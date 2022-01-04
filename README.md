# Installation
 
```
git clone https://github.com/shin0bi-y/vsh && cd vsh
chmod +x setup.sh
sudo bash setup.sh (remove sudo if you are already root)
```

Next, you have to install ssh on your machine

Ressource : 
https://wiki.archlinux.org/title/OpenSSH

# Usage

4 differents modes :

- **list** : 

prints what archives are stored on the server

```vsh -list <ip> <port>```


- **create** : 

creates an archive based on the current directory and send it to the server

```vsh -create <ip> <port> <archive_name>```


- **extract** : 

gets an archive from the server and recreates what is stored in it in the current directory

```vsh -extract <ip> <port> <archive_name>```


- **browse** : 

allows to explore an archive and modify it directly on the server

```vsh -browse <ip> <port> <archive_name>```
 
- **delete** : 

allows to remotly delete an archive

```vsh -delete <ip> <port> <archive_name>```
