# 🌍 Terraform Multi-Cloud Learning Project

Welcome to the **Terraform Multi-Cloud Learning Project**. This repository is designed to help learners understand how to use [Terraform](https://www.terraform.io/) to provision infrastructure on the three major cloud platforms:

- 🟠 **AWS**
- 🔵 **Azure**
- 🟡 **Google Cloud (GCP)**

This single repository includes foundational Terraform templates and best practices tailored to each cloud provider.

---

## 📁 Project Structure
````
terraformscrips/
├── aws/
│   ├── project1/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
│   ├── project3/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
├── azure/
│   ├── project1/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
│   ├── project3/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
├── gcp/
│   ├── project1/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
│   ├── project3/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
└── README.md

````

Each folder contains standalone Terraform configuration files for provisioning cloud infrastructure on the respective provider.

---

## 🔧 Prerequisites

Make sure you have the following tools installed:

### General

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (v1.0+)
- [Git](https://git-scm.com/)
- Code editor like [VS Code](https://code.visualstudio.com/)

### Provider-Specific

- **AWS**
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - An AWS IAM user with programmatic access and required permissions
- **Azure**
  - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  - An active Azure subscription and authenticated user
- **GCP**
  - [gcloud CLI](https://cloud.google.com/sdk/docs/install)
  - A Google Cloud project with billing enabled and appropriate IAM roles

---

## 🚀 Getting Started (Common Workflow)

Each cloud provider folder is a standalone Terraform module. Follow these steps inside `aws/`, `azure/`, or `gcp/`.

### 1. Navigate into a provider directory

```bash
cd aws  # or azure or gcp
````

### 2. Initialize the project

```bash
terraform init
```

### 3. Review planned changes

```bash
terraform plan
```

### 4. Apply the configuration

```bash
terraform apply
```

### 5. (Optional) Destroy the infrastructure

```bash
terraform destroy
```

---

## 📌 Best Practices for Terraform

Here are some recommended practices when writing and using Terraform:

### Code Structure

* Break configurations into **modules** for reuse.
* Keep `main.tf`, `variables.tf`, and `outputs.tf` logically organized.

### State Management

* Use **remote backends** (e.g., S3 for AWS, Azure Blob, GCS) for storing `.tfstate`.
* Protect state files with proper permissions and versioning.

### Version Control

* Add `.terraform/`, `.tfstate`, and credentials files to `.gitignore`.
* Never commit secrets or cloud credentials.

### Quality

* Format code using:

  ```bash
  terraform fmt
  ```
* Validate syntax with:

  ```bash
  terraform validate
  ```

### Resource Management

* Use meaningful **tags/labels** (e.g., `Environment`, `Project`, `Owner`) for all resources.
* Define **input variables** and **outputs** to increase reusability and flexibility.
* Avoid hardcoding values.

---

## 🔗 Reference Links

### Terraform Docs

* [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
* [Terraform CLI Commands](https://developer.hashicorp.com/terraform/cli/commands)

### Providers

* [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Tools

* [Terraform Cloud](https://developer.hashicorp.com/terraform/cloud-docs)
* [Visual Studio Code](https://code.visualstudio.com/)
* [Terraform Registry](https://registry.terraform.io/)

---


