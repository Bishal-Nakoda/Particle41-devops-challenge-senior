# Particle41-devops-challenge-senior

# 🌐 Flask IP Timestamp API - Cloud Run Deployment

This project demonstrates a minimal Flask API that returns the **current timestamp** and the **IP address** of the visitor. The application is Dockerized and deployed to **Google Cloud Run** using **Terraform**.

---

## 📋 Features

- ✅ Returns timestamp and visitor IP in JSON
- 🐳 Dockerized application (small, secure image)
- 🚀 Deployed on Google Cloud Run via Terraform
- 🛡️ Runs as a non-root user inside the container

---

## 📦 API Response Format

```json
{
  "timestamp": "2025-04-14 10:00:00",
  "ip": "203.0.113.1"
}
```
--- 

## 🐳 To containerize the source code, run the below commands:
```bash
docker build -t flask-ip-api app/.
docker run -p 8080:8080 flask-ip-api
curl http://localhost:8080
```

---
## To deploy the architecture using terraform, we need to follow certain prerequisites:
1. One should have the below permissions:
- Service Usage Admin or Editor or Owner (To enable the APIs)
- Cloud Run Admin
- Compute Admin
- Serverless VPC Admin
- Storage Admin

2. Provision an External Global IP

3. Create a multi-regional bucket to store the state files. 

4. Now, in main.auto.tfvars put the values of the environment variables:
- Bucket name created in the above step (It will store the .tfstate files in remote backend)
- Project ID
- ip name mapped to the domain (External IP which is reserved earlier)
- domain to be added (For testing, I am using nip.io domain. It is generally in the format of External_IP.nip.io e.g. 32.45.67.89.nip.io. Make sure the External_IP is the IP which we have reserved earlier)

5. Once added make sure gcloud is installed in your system to run the below command:
```bash
gcloud auth application-default login
```
If project is not set use the below command:
```bash
gcloud config set project PROJECT_ID
```

6. Run the below command in sequence:
```bash 
terraform init
terraform apply
```

## After everything is done, you can use your domain to access the cloud run.
Note: For testing purpose, I have use nip.io domains for e.g. 32.45.67.89.nip.io
