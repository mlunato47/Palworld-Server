# Prerequisites
* [An AWS account](https://aws.amazon.com/resources/create-account/)
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

# Instructions

## Deploying the Server

1. Clone this GitHub repo locally `git clone https://github.com/mlunato47/PalServer.git`.

2. Change the variables in the [vars.tf](https://github.com/mlunato47/PalServer/blob/main/vars.tf) file to your desired AWS region, the AWS  EC2 AMI ID for Ubuntu 22.04 in your desired region and your home IP (found by googling `what is my ip`).

3. Run terrafrom init from the main directory of the cloned repo to initialize Terrafrom.

        terraform init

4. Create an AWS access key for your IAM user [AWS Instructions on how to do so](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).

5. Export your aws access keys as environment variables 

        export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE

        export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

6. Run terraform plan to make sure there are no errors in your configuration.


        terraform plan 

7. If there are no errors run:

        terraform apply
    
    and type `yes` when prompted and hit enter

## Connecting to the Server

1. Change the permissions of the newly created ssh key

        chmod 400 palworldserver

2. Connect to your ec2 instance via ssh (replace "public-ip-of-ec2-instance with the Ip of your EC2 instane that was created)

        ssh -i palworldserver ubuntu@public-ip-of-ec2-instance
        


   Type `yes` when prompted and hit enter.

## Configuring the Server

1. Run the following command to enable ufw (Uncomplicated Firewall) 

        sudo ufw enable
    
    Type `y` when prompted and hit enter

2. Check status of the ufw port 8211 with the following command

        sudo ufw status | grep 8211

   Should Show

                8211                       ALLOW       Anywhere                  
                8211 (v6)                  ALLOW       Anywhere (v6)  

3. To download and install the Palworld server on our Linux system, we must use SteamCMD. SteamCMD is a command line interface we can use to download games and servers straight from Steam. Before installing this tool, we need to add the “i386” (32-bit) architecture to our systems package manager by using the following command. The reason for this is that SteamCMD is only offered as a 32-bit application

        sudo dpkg --add-architecture i386

4. With the 32-bit architecture added, our next step is to add the multiverse repository on Ubuntu

        sudo add-apt-repository multiverse
        
    Press enter to confirm

5. Since we have changed the available repositories on our Ubuntu system, we will need to update the package list again

        sudo apt update

6. Setup the port forwarding for the server by creating a new Nginx configuration file for your game server:


        sudo vi /etc/nginx/sites-available/palworld

    Paste the following into the file, be sure to replace your_ip with the public ip of your ec2 instance

        server {
            listen 8211;
            server_name your_ec2_public_ip;

            location / {
                proxy_pass http://127.0.0.1:8211;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }

    Hit the escape key and the type `:wq` and hit enter

7. Create a symbolic link to enable the site with the command below:

        sudo ln -s /etc/nginx/sites-available/palworld /etc/nginx/sites-enabled/

8. Before restarting Nginx, it's a good idea to test the configuration:

        sudo nginx -t

    Should see 
    
        nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
        nginx: configuration file /etc/nginx/nginx.conf test is successful

9. Restart Nginx to apply the changes:

        sudo service nginx restart

## Installing SteamCMD

1. Finally, we can install the SteamCMD tool to our system using the command below.

        sudo apt install steamcmd 

    Type `y` and hit enter

2. Scroll down the license acceptance and use the right arrow key to highlight "OK" and then hit enter

3. Press the down arrow key and hit enter on "I AGREE" hit enter to click ok

4. Press enter on "OK" on the next screen

5. Scroll down the list and then hit enter when you get to the bottom

6. We need to modify the “.bashrc” file to adjust the path environment variable. At the moment, the steam user will be unable to find the SteamCMD tool we just installed as the “/usr/games” path is missing. You can begin modifying this file by using the command below.

        sudo vi /home/steam/.bashrc

    Scroll to the bottom press "i" hit the right arrow key 2 times and then press enter twice to start a new line, paste the following line at the bottom of the file `export PATH="/usr/games/:$PATH"`

    then pres escape and `:wq` and hit enter to save and exit


## Installing the Palworld Server

1. To begin installing the Palworld dedicated server to our Ubuntu device, we will want to change to the “Steam” user we created earlier. You can swap to this user by running the following command.

        sudo -u steam -s

2. Now change to the home directory of this user by using the cd command below.

        cd ~

3. Installing the Palworld Server to your Ubuntu System
Before we can install and use the Palworld dedicated server we have to do some initial set up. By running the following command, we will be downloading the Steamworks SDK redistributable. We need a specific file from this to run the server.

        steamcmd +login anonymous +app_update 1007 +quit

4. Next, we must create a directory where the Palworld server will look for the “steamclient.so” file. Create this directory by using the mkdir command.

        mkdir -p ~/.steam/sdk64

5. With the directory created, we can copy over the “steamclient.so” library the server requires to run.

        cp ~/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so ~/.steam/sdk64/

6. We can now use the following command to download the Palworld dedicated server to our Linux machine. The server is fairly large, so this process may take a few minutes to complete.

        steamcmd +login anonymous +app_update 2394010 validate +quit

## Starting up our Palworld Dedicated Server

1. To begin this process, change to the directory where the start script is by typing in the command below.

        cd ~/Steam/steamapps/common/PalServer

2. Finally, you can start your server using the following command.
You will see a couple of errors as it first starts up, but you can ignore these issues unless they continue to appear after the initial startup.

        ./PalServer.sh

    You should know it is up and running if you see:

        Setting breakpad minidump AppID = 2394010
        [S_API FAIL] Tried to access Steam interface SteamUser021 before SteamAPI_Init succeeded.
        [S_API FAIL] Tried to access Steam interface SteamFriends017 before SteamAPI_Init succeeded.
        [S_API FAIL] Tried to access Steam interface STEAMAPPS_INTERFACE_VERSION008 before SteamAPI_Init succeeded.
        [S_API FAIL] Tried to access Steam interface SteamNetworkingUtils004 before SteamAPI_Init succeeded.

## Configuring your Palworld Server

1. After starting up your Palworld dedicated server, you will likely want to re-adjust the default settings. To give you a good base, let us make a copy of the default settings using the command below.

        cp ~/Steam/steamapps/common/PalServer/DefaultPalWorldSettings.ini ~/Steam/steamapps/common/PalServer/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini

    now you can shut the server down and edit the configs you you would like to shut the server down press `cntrl+c`

2. You can now begin modifying the configuration file by using the vi text editor.

        vi ~/Steam/steamapps/common/PalServer/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini

    Within this file, you will find an assortment of different values that you can configure. We won’t be diving into all of these, but you can check out the [official documentation](https://tech.palworldgame.com/optimize-game-balance) to learn more.


3. One option you will likely want to change is the server password. Setting a password stops just anyone from hopping on your Palworld server. To set the password, find the following setting within the file. ServerPassword="" Once you find the option, type in a password between the double quotes (""). once you are ready to save hit esape and then type `:wq`


## Setting the Server to run on Startup

1. If you are still using the Steam user from earlier, you will want to return to your normal user using the following command.

        exit

2. We can begin writing a service file for our Palworld server by typing in the command below.

        sudo vi /etc/systemd/system/palworld.service

    Within this file, type in the following lines.

    These lines will automatically start your Palworld server when your Ubuntu device powers on. Additionally, before it starts, the service will use SteamCMD to check for updates.

        [Unit]
        Description=Palworld Server
        Wants=network-online.target
        After=network-online.target

        [Service]
        User=steam
        Group=steam
        WorkingDirectory=/home/steam/
        ExecStartPre=/usr/games/steamcmd +login anonymous +app_update 2394010 +quit
        ExecStart=/home/steam/Steam/steamapps/common/PalServer/PalServer.sh -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS > /dev/null
        Restart=always

        [Install]
        WantedBy=multi-user.target

    Then hit escape and type `:wq` and hit enter

3. With the service now written, we must enable it using the command below. Enabling the service allows the system manager to start your Palworld server automatically when your operating system starts.

        sudo systemctl enable palworld

    If you want the server to start immediately, all you need to do is use the command below. This command tells the system manager to start our Palworld server immediately.

        sudo systemctl start palworld

    To stop the Palworld server from running, you must run the command below.
    
         sudo systemctl stop palworld

    You can also stop the server from running at startup by turning off the Palworld service we created.

        sudo systemctl disable palworld
 
## Automating Backup of Saves

1. Make a new directory for the steam user where backups will be saved:

        sudo mkdir /home/steam/backups

2. To do this we will use a cron job that runs once a day to backup your files:

        sudo crontab -e

    Type `1` and hit enter

    Copy the following to create the job

        0 0 * * * sudo cp -r home/steam/Steam/steamapps/common/PalServer/Pal/Saved/SaveGames/0/* /home/steam/backups/ >> /home/steam/cron_log.txt 2>&1

    This will backup the saves everyday at midnight


## Connecting to your Server

1. Try connectiong to the server from you palworld game, connect using the public ip of the ec2 instance and the palworld server port "8211"

## Teardown 

1. To delete and teardown all of this infrastructure created in AWS run the `terraform destroy` command from the main directory of the cloned repo when prompted type `yes` and hit enter

# WARNING: Doing so will destory all of the infrastructure and you will lose your server and all of the saves as well