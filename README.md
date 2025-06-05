<!-- hide -->
# Setting Up a Secure Server with SSL/TLS Using OpenSSL

> By [@rosinni](https://github.com/rosinni) and [other contributors](https://github.com/breatheco-de/set-up-an-SSL-in-openSSL-with-a-secure-server/graphs/contributors) at [4Geeks Academy](https://4geeksacademy.co/)

[![build by developers](https://img.shields.io/badge/build_by-Developers-blue)](https://4geeks.com)
[![build by developers](https://img.shields.io/twitter/follow/4geeksacademy?style=social&logo=twitter)](https://twitter.com/4geeksacademy)

*These instructions are [available in Spanish](https://github.com/breatheco-de/set-up-an-SSL-in-openSSL-with-a-secure-server/blob/main/README.es.md)*

### Before Starting...

> We need you! These exercises are created and maintained in collaboration with people like you. If you find any errors or typos, please contribute and/or report them.

<!-- endhide -->

## 🌱 How to start this project?

This exercise aims to teach students how to set up a secure server using OpenSSL to provide secure communications via SSL/TLS.

### Requirements

* A Debian virtual machine installed in VirtualBox. (we will use the previously configured machine in previous classes).

## 📝 Instructions

* Open this URL and fork the repository https://github.com/breatheco-de/set-up-an-SSL-in-openSSL-with-a-secure-server

 ![fork button](https://github.com/4GeeksAcademy/4GeeksAcademy/blob/master/site/src/static/fork_button.png?raw=true)

A new repository will be created in your account.

* Clone the newly created repository into your localhost computer.
* Once you have cloned successfully, follow the steps below carefully, one by one.

### Step 1: Generate a Private Key and a Certificate Signing Request (CSR):

In an HTTPS connection, the web server needs to **prove its identity and encrypt the communication**. For this, a digital certificate is used, which contains a public key; this public key is useless without its corresponding private key. The **private key** is a secret file that allows encrypting and decrypting data. Now, we will generate a private key using **OpenSSL**, a command-line tool for creating and managing certificates and cryptography.

- [ ] Open a terminal and run the following command to generate a 2048-bit RSA private key:
    ```sh
    openssl genrsa -out /etc/ssl/private/myserver.key 2048
    ```
    > 💡Make sure to protect this private key properly.

    Verify that the file was created:

    ```bash
    ls -l /etc/ssl/private/myserver.key
    ```

    Expected result:

    ```bash
    -rw------- 1 root root 1675 Jun  4 18:30 /etc/ssl/private/myserver.key
    ```

Now we need to make a **Certificate Signing Request (CSR)**. This is a file that contains the **public key** you want to certify and information about your **organization or server** (country, city, name, domain, email, etc.).

> This file is usually sent to a **Certificate Authority (CA)**, such as Let's Encrypt or DigiCert, to issue a **valid digital certificate**. In our lab, we will not send it to a CA, but we will **sign it ourselves (self-signed)**. However, the process is the same.

- [ ] Use the following command to generate a CSR that will contain the public information to be included in the certificate:
    ```sh
    openssl req -new -key /etc/ssl/private/myserver.key -out /etc/ssl/certs/myserver.csr
    ```
    **During the process, you will be prompted to enter information about your organization.** 
    (Here is an example of how you can complete it):
    * Country Name (2 letter code): ES
    * State or Province Name (full name): Madrid
    * Locality Name (eg, city): Madrid
    * Organization Name (eg, company): MyCompany
    * Organizational Unit Name (eg, section): IT
    * Common Name (eg, fully qualified host name): my-domain.com
    * Email Address: admin@my-domain.com


### Step 2: Sign the CSR to Obtain a Self-Signed Certificate:
Once we have the `.csr` file (the certificate request), we need to **sign it** to generate the final `.crt` certificate. In a real environment, this step would be done by a **Certificate Authority (CA)**, which would verify your identity and sign the CSR to issue a trusted certificate.


- [ ] For the purposes of this practice, we will sign the CSR with our own private key to obtain a self-signed certificate, use the following command (This will generate a self-signed certificate valid for 365 days):
    ```sh
    openssl x509 -req -days 365 -in /etc/ssl/certs/myserver.csr -signkey /etc/ssl/private/myserver.key -out /etc/ssl/certs/myserver.crt
    ```

    - `x509`: Generates a certificate in standard X.509 format.
    - `-req`: Indicates that the input file is a CSR request.
    - `-days 365`: The certificate will be valid for 365 days.
    - `-in /etc/ssl/certs/myserver.csr`: CSR file that we will sign.
    - `-signkey /etc/ssl/private/myserver.key`: Private key used to sign the CSR.
    - `-out /etc/ssl/certs/myserver.crt`: Name of the resulting file (the final certificate).

### Step 3: Configure Apache to Use the SSL Certificate:

Now that we have the certificate (`myserver.crt`) and the private key (`myserver.key`), we need to tell Apache to use them when serving content over HTTPS. 

- [ ] Check the SSL configuration file for Apache:
    ```sh
    sudo nano /etc/apache2/sites-available/default-ssl.conf
    ```

- [ ] Make sure the file contains the following:
    ```sh
      <IfModule mod_ssl.c>
          <VirtualHost _default_:443>
              ServerAdmin admin@my-domain.com
              ServerName my-domain.com

              DocumentRoot /var/www/html

              SSLEngine on
              SSLCertificateFile /etc/ssl/certs/myserver.crt
              SSLCertificateKeyFile /etc/ssl/private/myserver.key

              <FilesMatch "\.(cgi|shtml|phtml|php)$">
                  SSLOptions +StdEnvVars
              </FilesMatch>
              <Directory /usr/lib/cgi-bin>
                  SSLOptions +StdEnvVars
              </Directory>

              BrowserMatch "MSIE [2-6]" \
                  nokeepalive ssl-unclean-shutdown \
                  downgrade-1.0 force-response-1.0

              BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

          </VirtualHost>
      </IfModule>
    ```

    Ensure that:
    - The `ServerName` matches the **Common Name (CN)** of the self-signed certificate.
    - `SSLEngine on`: The SSL engine for this site is enabled to `on`.
    - `SSLCertificateFile`: Path to the .crt file (the public certificate)
    - `SSLCertificateKeyFile`: Path to the .key file (the private key associated with the certificate).

### Step 4: Enable the SSL Site and SSL Module:
- [ ] Use the following commands to enable the SSL module and load the HTTPS site configuration:

    ```sh
    sudo a2enmod ssl
    sudo a2ensite default-ssl
    sudo systemctl reload apache2
    ```
### Step 5: Update the Hosts File:
- [ ] Check the /etc/hosts file on your local machine (from where you access the virtual machine) to ensure that my-domain.com resolves to 127.0.0.1
    ```sh
    sudo nano /etc/hosts
    ```
  > 💡 Make sure to add the line:
    * 127.0.0.1 my-domain.com

- [ ] Restart the virtual machine to apply all changes

 
### Step 6: Test the Connection:
- [ ] Open a web browser and enter the URL https://my-domain.com. You should see a security warning due to the self-signed certificate. Accept the risk and continue to see the default Apache page served over HTTPS.

![my-domain.com](https://github.com/breatheco-de/set-up-an-SSL-in-openSSL-with-a-secure-server/blob/main/assets/https.png)


> 💡 NOTE: For the purposes of this educational exercise, while using localhost with HTTPS (https://localhost/) is sufficient to demonstrate the basic setup of SSL/TLS using OpenSSL, including the configuration of a custom domain like my-domain.com provides a more comprehensive and practical learning experience. This additional step allows understanding how DNS resolution works in a real environment. When generating the SSL/TLS certificate, it is crucial that the domain name (Common Name) matches the domain used to access the server, thus avoiding errors and security warnings in browsers. This reinforces the understanding of essential concepts and enhances the practical skills needed to handle SSL/TLS configurations in a professional environment.

## 🚛 How to submit this project?

We have developed a script to help you measure your success during this project.

- [ ] In the `./assets` folder, you will find the script [check_ssl.sh](https://github.com/breatheco-de/set-up-an-SSL-in-openSSL-with-a-secure-server/blob/main/assets/check_ssl.sh) that you should copy and paste onto the desktop of your Debian virtual machine.

- [ ] Once you have pasted the script [check_ssl.sh](https://github.com/breatheco-de/set-up-an-SSL-in-openSSL-with-a-secure-server/blob/main/assets/check_ssl.sh) on your Debian machine, open the terminal and navigate to the directory where the script is located, in our case `./Desktop`, and make the script executable (if it is not already). This can be done using the `chmod` command:
  ```sh
  chmod +x check_ssl.sh
  ```

- [ ] Run the script specifying its name. You may also provide any necessary arguments. Assuming no additional arguments are needed for this example, you should run:
  ```sh
  ./check_ssl.sh
  ```

- [ ] **Upload your results.** Running the script will create a `report.json` file that you should copy and paste into the root of this project. 