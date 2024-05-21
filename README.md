# MailServer
Fast and easy automated deployment of a mail server.

Creates a mail server with 1 and optionally 2 domains, to get you started and nearly done with the setup of a mail server with a GUI for webmail and another one to administrate the server; there you can add more users, domains and anything you want easily later. 
Make sure you have setup the DNS (A, MX, TXT) records before you deploy it. You should even use a PTR record in DNS for reverse look ups and make your service more secure. 

# Instructions

0- DON'T FORGET TO EDIT THE Dockerfile !!!!!!!!!!!!!!!

1- Save the Dockerfile and the scripts in the same directory.

2- Build the Docker Image:

docker build -t mail_server_image .

3a- Run the Docker Container for 1 domain:

docker run -d --name mail_server_container -e DOMAIN1=maxhaase.com -e USER=user -e EMAIL=admin@example.com mail_server_image

3b- Run the Docker Container for 2 domains:

docker run -d --name mail_server_container -e DOMAIN1=maxhaase.com -e DOMAIN2=example.com -e USER=user -e EMAIL=admin@example.com mail_server_image

This setup allows the second domain to be optional and reads all variables from environment variables specified in the Dockerfile. 
The script provisions the mail server according to the specified configuration.
