## Running terraform

Pre-requisites:

1. Create an IAM access key with admin credentials

2. Install awc-cli:

    ```shell
    sudo apt install awscli
    aws configure # Enter access key id and secret
    ```

3. Obtain the following data from cloudflare:
    - zone id
    - account id
    - generate a token -- with read permissions for dns

4. Generate a pair of ssh keys:

    ```shell
    ssh-keygen -m PEM
    ```

5. Generate a pair of PGP keys

    ```shell
    gpg --full-generate-key
    ```

6. Export PGP public key as non-armor and base64 encoded (format supported by terraform):

    ```shell
    gpg --export your_key_id | base64 > pgp_key.pub.b64
    gpg --export-secret-keys --armor your_key_id > pgp_key
    ```

7. Create a `terraform.tfvars` file (use the `tfvars.sample` as a reference).

8. Create an app in Vault Secrets (optional).

9. Create a service principal credential with access to Vault Secrets (optional).

10. Store keys and the `*.tfvar` file in Vault Secrets (optional):

    ```shell
    hcp auth login
    cat <ssh_priv_key> | hcp vault-secrets secrets create SSH_PRIVATE_PEM --data-file=-
    cat <ssh_pub_key> | hcp vault-secrets secrets create SSH_PUBLIC --data-file=-
    cat <pgp_pub_b64_key> | hcp vault-secrets secrets create PGP_PUBLIC_B64 --data-file=-
    cat <pgp_priv_armor> | hcp vault-secrets secrets create PGP_PRIVATE_ARMORED --data-file=-
    cat <tfvars_file> | hcp vault-secrets secrets create TFVARS --data-file=-
    ```

### Saving state locally

Remove the `backend` block in `main.tf` and set all the required values in `.env`. Then:

```shell
source .env && terraform init
terraform apply
```

Note

You can provide both ssh and pgp public keys from a file -- or as a hardcoded value -- for testing purpose (in that case you should edit `main.tf`). But if you are using this repo in production you should consider a 3rd party vault solution.

### Saving state in remote

Set the values in `*.remote.tfbackend` (ex: `dev.remote.tfbackend`; use `sample.remote.tfbackend` as reference).

Add the file from previous step to `.remote.env` 

Login, init and apply:

```shell
hcp auth login
source .remote.env && terraform init
terraform apply
```