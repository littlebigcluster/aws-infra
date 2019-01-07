# Cluster SWARM

1- Create custom AMI ( debian, docker version ... )

2- Create Cluster SWARM (par ex: 3 Managers + 2 Workers )

When you specify tour variables-template:
environment: staging
domain_name: mydomain.com

entry DNS in route53 below are created:
- traefik-staging.mydomain.com 
- portainer-staging.mydomain.com 
