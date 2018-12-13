# GitLab haute disponibilité sur AWS

Création d'un Gitlab en haute dispo dans un VPC AWS préalablement créé via:

https://github.com/littlebigcluster/aws-base

La haute disponibilité passera par l'utilisation de certains services managés AWS type:

* EFS (system de fichier via NFS)
* RDS ( base POSTGRESQL)
* Elasticache ( Redis)
* S3 ( sauvegarde)


![vpc-nat-gateway](img/Architecture_AWS.png)

## Prerequis


* [Terraform](https://www.terraform.io/downloads.html)
* [aws-cli](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/installing.html)
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

Avoir configuré ses credentials AWS:
```
aws configure
```

## Demarrage:

Définir toute les variables souhaitées dans les fichiers :
* variables.template
* variables.tfvars
* group_var/all


## Lancement:

Lancer le script sh ( reprend l'ensemble des commandes terraform ):
```
./init.sh
```


## Fonctionnement


* Creation d'une base sur RDS (PostgreSQL engine).
* Creation d'un elasticache service (Redis).
* Creation d'un EFS service disponible dans les 3 zones privées.
* Creation d'une instance EC2 qui fonctionne comme un seed pour le lancement de la configuration.
* Cette instance seed est configurée avec ansible et gitlab omnibus.
* 2 Load Balancer sont créés. ( 1 lb application avec une clef ACM aws associée, et 1 lb network pour les accés ssh au gitlab)
* Une AMI est créée depuis cette instance seed
* Un Autoscaling groupe est créé avec cette AMI
* Un Bucket S3 est reservé à la sauvegarde
* Un backup de gitlab sur S3 est croné toutes les heures

## Ressources AWS utilisées:

* VPC
* subnets
* Security Groups
* RDS (PostgreSQL)
* Elasticache (redis)
* EFS
* EC2
* LB ( Application & Network )
* Launch configuration
* Autoscaling
* S3




### Ressources

Fork du repo:
https://github.com/skysec/gitlab-ha-aws