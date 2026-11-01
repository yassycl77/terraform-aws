# EC2 Ubuntu avec Terraform

Projet a placer dans votre depot Git puis a cloner sur Ubuntu. Aucun depot distant n'est cree et aucune ressource AWS n'a ete deployee lors de la preparation.

## Ressources

Region eu-west-3 (Paris), Ubuntu Server 24.04 LTS amd64, t3.micro, disque gp3 chiffre de 20 Gio, VPC dedie, sous-reseau public, passerelle Internet et IPv4 publique attribuee automatiquement. SSH est le seul port entrant, limite a une IPv4 /32. Aucun logiciel applicatif n'est installe. IMDSv2 est obligatoire.

L'instance, le disque EBS et l'IPv4 publique peuvent generer des frais. Aucune eligibilite a une offre gratuite n'est supposee. L'adresse publique peut changer apres un arret/redemarrage. Ce projet convient a une instance simple ; il ne fournit ni sauvegarde ni haute disponibilite.

## Prerequis Ubuntu

- Git, OpenSSH client, Terraform >= 1.6 et < 2 et AWS CLI v2.
- Installer Terraform : https://developer.hashicorp.com/terraform/install
- Installer AWS CLI : https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Identite AWS autorisee a gerer les ressources EC2/VPC et les tags, a decrire les zones et a lire le parametre public SSM de Canonical. Les controles de votre organisation peuvent limiter ces operations.

Configurer votre profil AWS (SSO recommande si disponible dans votre organisation) :

```bash
aws configure sso --profile terraform
aws sso login --profile terraform
export AWS_PROFILE=terraform
aws sts get-caller-identity
```

Vous pouvez aussi utiliser un profil AWS CLI deja configure. Aucune cle AWS ne doit etre ajoutee aux fichiers Terraform.

## Premier deploiement

Apres publication dans votre propre depot :

```bash
git clone <URL_DE_VOTRE_DEPOT>
cd <DOSSIER_DU_DEPOT>
```

Depuis le dossier contenant main.tf, creer une cle dediee si elle n'existe pas deja (choisir une phrase de passe) :

```bash
ssh-keygen -t ed25519 -f "$HOME/.ssh/terraform-ec2"
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Remplacer `203.0.113.10/32` par votre IPv4 publique suivie de `/32`. Cette adresse d'exemple ne permet pas votre connexion. Adapter le chemin de la cle publique si necessaire ; la cle privee reste sur votre machine. En cas de changement d'IP publique, mettre a jour cette variable puis relancer plan et apply.

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=deploy.tfplan
terraform apply deploy.tfplan
ssh -i "$HOME/.ssh/terraform-ec2" "$(terraform output -raw ssh_destination)"
```

Examiner le plan avant apply : le plan sauvegarde est applique sans nouvelle confirmation. Attendre un peu si SSH n'est pas encore disponible au premier demarrage.

Conserver et versionner `.terraform.lock.hcl`, genere par init, pour verrouiller les versions des fournisseurs. Ne pas versionner terraform.tfvars, les plans, l'etat ou les cles privees ; le .gitignore les exclut.

## Etat et changements

L'etat est local dans terraform.tfstate : le conserver avec soin, avec sa sauvegarde, hors du depot. Ne pas supprimer l'etat avant la destruction. Ne pas lancer plusieurs operations simultanees depuis des copies differentes. Un backend S3 avec verrouillage sera preferable pour un usage partage.

Le parametre Canonical fournit l'AMI stable courante. Une nouvelle AMI peut provoquer un remplacement de l'instance lors d'un futur plan. Toujours examiner le plan ; le disque racine est supprime avec l'instance. Sauvegarder les donnees utiles avant remplacement ou destruction.

## Nettoyage

Depuis le meme dossier, avec le meme etat et le meme compte/profil AWS :

```bash
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Cette operation supprime toutes les ressources gerees par ce projet et les donnees du disque racine.

## Verification de cette livraison

Les fichiers ont ete prepares sans execution de Terraform : le binaire n'est pas disponible dans l'environnement de preparation. Aucun terraform init/validate/plan ni test AWS n'a ete execute. Executer les commandes ci-dessus sur Ubuntu avant le deploiement.

## Documentation

- Parametres des AMI officielles Ubuntu : https://ubuntu.com/aws/docs/aws-how-to/instances/build-cloudformation-templates/
- Ressource EC2 Terraform : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
