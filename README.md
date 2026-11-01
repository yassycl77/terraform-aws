# Terraform AWS : laboratoire d'industrialisation

Ubuntu 24.04 amd64, T3, VPC dedie, sous-reseau public, SSH depuis une IPv4 /32,
IMDSv2 obligatoire et disque gp3 chiffre. Les ressources AWS sont facturables.
Ce laboratoire ne fournit pas de haute disponibilite ni de sauvegarde automatique.

## Organisation

- Racine : environnement **dev existant**, conserve ici pour garder son etat.
- `modules/network` : VPC, sous-reseau, Internet Gateway et routage.
- `modules/ec2` : instance, disque, cle publique et regles SSH.
- `environments/prod` : exemple independant non deploye, avec ses propres variables et etat.
- `bootstrap` : bucket S3 pour les etats, gere dans un etat separe.
- `.github/workflows/terraform.yml` : formatage, validation et tests simules sans acces AWS.

En entreprise, completer l'isolation par des comptes et roles distincts. Les noms et tags
ne constituent pas une frontiere de permissions.

## Prerequis

Terraform >= 1.10 et < 2, Git, AWS CLI v2 et OpenSSH. La CI utilise Terraform 1.10.5.
Le profil doit gerer EC2/VPC et lire le parametre SSM Canonical si `ami_id` n'est pas fourni.
Le bootstrap et le backend necessitent aussi des droits S3. Ne jamais utiliser de cle root.

```bash
export AWS_PROFILE=terraform
aws sts get-caller-identity
```

## Migration de l'instance existante sur Ubuntu

Rester dans `/opt/terraform/terraform-aws`, avec le meme compte et le meme etat.
Ne pas lancer d'operations concurrentes. Avant de mettre a jour le code :

```bash
cd /opt/terraform/terraform-aws
umask 077
terraform state pull > ../terraform-aws-before-modules.tfstate.backup
aws ec2 describe-instances \
  --instance-ids "$(terraform output -raw instance_id)" \
  --region eu-west-3 \
  --query 'Reservations[0].Instances[0].[ImageId,Placement.AvailabilityZone]' \
  --output text
git status
git pull --ff-only
```

Si `git pull` est bloque par un formatage local de main.tf, examiner `git diff` et conserver
les changements utiles avant de resoudre le conflit. Ne pas reinitialiser aveuglement le depot.

Dans le fichier **existant** `terraform.tfvars`, conserver les valeurs actuelles (nom, type,
disque, cle et CIDR). Ajouter `ami_id` et `availability_zone` avec les valeurs relevees.
Cela evite qu'une nouvelle AMI Canonical ou un changement de zone ne remplace l'instance.
Ne pas ecraser les variables existantes avec le fichier d'exemple.

```hcl
environment = "dev"
owner       = "platform"
# Remplacer par les vraies valeurs relevees :
# ami_id            = "ami-0123456789abcdef0"
# availability_zone = "eu-west-3a"
```

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=migration.tfplan
```

Les dix blocs de `moved.tf` reassocient les ressources aux modules. Le plan attendu
comporte **0 ajout et 0 destruction**, avec eventuellement une mise a jour des tags
Environment/Owner. Si le plan annonce une creation, destruction ou un remplacement,
ne pas appliquer : verifier etat, AMI, zone et variables. Seul le plan sur l'etat reel
peut confirmer l'absence de remplacement.

Apres examen du plan :

```bash
terraform apply migration.tfplan
terraform output
ssh -i "$HOME/.ssh/terraform-ec2" "$(terraform output -raw ssh_destination)"
```

Conserver les blocs moved pour les copies qui n'ont pas migre. Ne pas reutiliser un ancien
`deploy.tfplan` apres changement du code. Sauvegarder les donnees utiles avant toute operation.

## Nouvelle installation

```bash
git clone https://github.com/yassycl77/terraform-aws.git
cd terraform-aws
# Creer uniquement si cette cle n'existe pas deja.
ssh-keygen -t ed25519 -f "$HOME/.ssh/terraform-ec2"
cp terraform.tfvars.example terraform.tfvars
```

Renseigner l'IPv4 publique du poste SSH suivie de `/32` et le chemin de la cle publique.
Choisir idealement une AMI Ubuntu amd64 de la region dans `ami_id`. Sans cette variable,
la recherche Canonical courante peut provoquer un remplacement lors d'une mise a jour.
Le disque racine est supprime avec l'instance. Aucune cle privee ne doit entrer dans Terraform.

```bash
terraform init
terraform validate
terraform plan -out=deploy.tfplan
terraform apply deploy.tfplan
```

Examiner le plan : son application ne demande pas de nouvelle confirmation. Versionner les
`.terraform.lock.hcl` de chaque environnement. Ne publier ni etat, ni plan, ni variables privees.

## Backend S3 : activation apres la migration des modules

Le backend est prepare mais desactive par defaut : l'etat existant reste local.
Avec un profil autorise pour S3, choisir un nom de bucket globalement unique :

```bash
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -var='state_bucket_name=NOM-UNIQUE-DU-BUCKET' -out=bootstrap.tfplan
terraform -chdir=bootstrap apply bootstrap.tfplan
cp backend.tf.example backend.tf
cp backend.hcl.example backend.hcl
```

Modifier backend.hcl avec le bucket cree et conserver la cle dev. Le bucket a le
versionnement, le chiffrement, le blocage public, une politique TLS et prevent_destroy.
L'etat bootstrap reste local et doit etre sauvegarde hors Git.

Avec une nouvelle sauvegarde de l'etat dev et sans operation concurrente :

```bash
terraform init -migrate-state -backend-config=backend.hcl
terraform state list
terraform plan
```

Accepter la copie apres verification du bucket et de la cle. Ne pas remplacer cette
migration par `-reconfigure`. Le verrouillage natif S3 exige Terraform >= 1.10.
Le role operateur doit pouvoir lister le bucket, lire/ecrire l'etat, et lire/ecrire/supprimer
son objet `.tflock`. Les permissions de creation du bucket sont distinctes de son utilisation.

Pour prod, utiliser les exemples dans environments/prod, une cle d'etat /prod/ et des
variables propres. Ne jamais copier l'etat dev dans prod. Aucun environnement prod
n'est cree automatiquement.

## CI et tests

Les push sur main et pull requests executent fmt, init sans backend et validate sur les
configurations, ainsi que des tests simules du module EC2 (IMDSv2, chiffrement, restriction
SSH et rejet d'une instance ARM). Ils ne prouvent pas les permissions ni la capacite AWS.

```bash
terraform -chdir=modules/ec2 init -backend=false
terraform -chdir=modules/ec2 test
```

La CI n'execute ni plan AWS ni apply. Le lint, le scanner de securite et le deploiement OIDC
sont des etapes suivantes. Pour un deploiement GitHub : role OIDC limite au depot,
backend distant actif et environnement GitHub avec approbation ; pas de cle AWS permanente.

## Nettoyage

Depuis l'environnement concerne et avec son etat :

```bash
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Cela detruit l'instance, ses donnees et son reseau, mais pas le bootstrap S3.

## References

- https://developer.hashicorp.com/terraform/language/modules/configuration
- https://developer.hashicorp.com/terraform/language/backend/s3
- https://github.com/hashicorp/setup-terraform

## Verification de cette revision

Terraform 1.10.5 / fournisseur AWS 6.71.0 : fmt recursif et validation des cinq
configurations reussis ; trois tests simules reussis. Aucun plan sur l'etat Ubuntu
ni deploiement AWS execute depuis cet environnement.
