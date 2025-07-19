
# OpenStack on AWS (Kolla-Ansible)

This project provisions an OpenStack environment using **Kolla-Ansible** on **AWS EC2 instances**, managed via **Terraform** and **Ansible**. It includes automated deployment, scaling, and validation tasks.

## 📁 Project Structure

```
openstack-kolla/
├── main.tf              # Terraform resources (EC2, networking)
├── outputs.tf           # Terraform output variables
├── variables.tf         # Terraform input variables
└── ansible/             # Ansible playbooks and roles
    ├── deploy.yml       # Main playbook to orchestrate OpenStack setup
    ├── files/
    │   └── globals.yml  # Global Kolla configuration
    └── roles/
        ├── prepare_nodes/
        ├── prepare_deployment_node/
        ├── configure_kolla/
        ├── deploy_openstack/
        ├── network_config/
        ├── security_config/
        ├── monitoring_check/
        ├── scale_nova/
        ├── scale_swift/
        └── validation/
```

## 🚀 How to Deploy

1. **Provision infrastructure with Terraform:**

```bash
cd openstack-kolla
terraform init
terraform apply
```
**Note:** The Ansible playbook is automatically executed at the end of the Terraform apply phase using a local provisioner. You can still run it manually if needed.

2. **Run the Ansible playbook manually:**

```bash
ansible-playbook -i generated_inventory.ini -u ubuntu --private-key ~/.ssh/my-aws-key.pem ansible/deploy.yml
```

## ✅ Features

- Kolla-Ansible based OpenStack deployment
- Auto-scaling for Nova (via Heat)
- Dynamic scaling for Swift storage
- Validation checks for Nova, Swift, and Trove
- Monitoring pre-checks and post-deployment tasks

## 📝 Notes

A detailed documentation file is included separately that explains the architecture, automation logic, and troubleshooting tips.
