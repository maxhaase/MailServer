# MailServer
Easy automated deployment of a complete mail server in minutes.

Creates a complete mail server with 1 and optionally 2 domains, to get you started and nearly done with the setup of a mail server with a GUI for webmail and another one to administrate the server; there you can add more users, domains and anything you want easily later. <br>
Make sure you have setup the DNS (A, MX, TXT) records before you deploy it. <br>
You should even use a PTR record in DNS for reverse look ups and make your service more secure. 

# Instructions

0- DON'T FORGET TO EDIT THE Dockerfile and the run command !!!!!!!!!!!!!!!

1- Save the Dockerfile and the scripts in the same directory.

2- Build the Docker Image:

docker build -t mail_server_image .

3a- Run the Docker Container for 1 domain:

  docker run -d --name mail_server_container \
  -e DOMAIN1=example1.com \
  -e USER=user \
  -e EMAIL=max@maxhaase.com \
  -e USER_PASSWORD=ChangeMe \
  -e MYSQL_ROOT_PASSWORD=ChangeMe \
  -e MYSQL_POSTFIX_PASSWORD=ChangeMe \
  -e ROOT_PASSWORD=ChangeMe \
  -e HOSTNAME=mail.example.com \
  mail_server

3b- Run the Docker Container for 2 domains:

  docker run -d --name mail_server_container \
  -e DOMAIN1=example1.com \
  -e DOMAIN2=example2.com \
  -e USER=user \
  -e EMAIL=max@maxhaase.com \
  -e USER_PASSWORD=ChangeMe \
  -e MYSQL_ROOT_PASSWORD=ChangeMe \
  -e MYSQL_POSTFIX_PASSWORD=ChangeMe \
  -e ROOT_PASSWORD=ChangeMe \
  -e HOSTNAME=mail.example.com \
  mail_server

This setup allows the second domain to be optional and reads all variables from environment variables specified in the Dockerfile and command line. 
The script provisions the mail server according to the specified configuration.

# Update DNS Records
Taking in consideration that the domains exist and the default values are already there, these examples can help you setup what you'll need. 
Notice that you could host the web servers and everything on the same host, but that is not recommended, instead you should use another docker and 
add it to the orchestration. Use the WordPress code in the project to create 1 or 2 WordPress sites and wrap it all up with Kubernetes.

##########################################<br>
A Record for mail.example.com:
Name: mail
Type: A
IP Address: The public IP address of your mail server

MX: @ 10 mail.example.com
A: mail The public IP address of your mail server

Name: email
Type: CNAME
Value: mail.example.com.

Name: TXT
Type: @
Value: v=spf1 a mx ip4:The public IP address of your mail server ~all

Name: TXT
Type: @	
Value: mail._domainkey IN TXT ( "v=DKIM1; h=rsa-sha256; k=rsa; s=email; " "p=THE PUBLIC KEY OF YOUR MAIL SERVER" ) ; ----- DKIM key mail for mail.example.com

Name: TXT
Type: PRT
Value: For improved security, you should have a reverse lookup record. If you don't have your own DNS server, you might have to ask your host provider to help you. 
If they refuse, then you can create your DNS server container to get around that.

##########################################<br>
MX Record for example1.com:
Name: @
Type: MX
Priority: 10 (or any other appropriate value)
Mail Server: mail.example.com

##########################################<br>
MX Record for example2.com:
Name: @
Type: MX
Priority: 10 (or any other appropriate value)
Mail Server: mail.example.com
