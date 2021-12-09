## Scope
Fail2ban is dope and SSH is quite secure, but what if someone still manages to authenticate to your machine e.g. by using saved/harvested credentials? Receive email alerts on successful ssh logins based on a predefined IP whitelist OR a predefined IP country origin whitelist.  Essentially: IF (ssh successful authentication ip address NOT IN ip whitelist) OR (ssh successful authentication ip address country of origin NOT IN country whitelist); then send email notification;

## Notification
![Notification example.png](https://i.ibb.co/550xtBv/logalert.png)

## Requirements
1. `sudo apt install geoip-bin`
2. A domain name.
3. A mailgun account (https://www.mailgun.com/).

## Configuration
1. Edit variables $country_whitelist OR $ip_whitelist in ssh-log-alert.sh to your needs.
2. Edit the script and replace your mailgun API, domain name, from-address and to-address in function mailgun_send_alert().


## Usage
`sudo chmod +x ssh-log-alert.sh`  

There are two ways to use this script:
1. Simply run the script (as root) which will result in a live log of every succesfull ssh authentication as well as an indication of email alert trigger success/failure, when a condition is met (you should test it that way also).  
`./ssh-log-alert.sh`
2. Add script to the root crontab and have it run in the background when the machine starts:  
`crontab -e`  
then add line:  
`@reboot /bin/bash /path/to/ssh-log-alert/ssh-log-alert.sh`  
reboot the machine and you are good to go (`reboot now`).

## About Mailgun
If you have never used it:
1. You need to have a domain (you can purchase one from multiple services such as https://www.namecheap.com/).
2. Create mailgun account and upgrade it (you need to add payment data but the service is free of charge).
2. After you upgrade, you'll need to update your DNS records according to the instructions provided by mailgun.

You could ofcourse edit the script and replace Mailgun with another SMTP service.

