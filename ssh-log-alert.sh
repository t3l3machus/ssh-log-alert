#!/bin/bash
#
# Author: Panagiotis Chartas
# Website: https://github.com/t3l3machus
# Requirements: apt install geoip-bin

country_whitelist="" #Leave blank to enable ip whitelist based alerts!!! Example: "China England"
ip_whitelist="" #Example: "84.51.23.123 56.156.12.96"

#Check if both whitelists are empty
if [ ${#country_whitelist} -eq 0 ] && [ ${#ip_whitelist} -eq 0 ]; then
    echo -e "\n[X] Ivalid alert trigger configurations. Check whitelists.\n"
    exit 1
fi

#Check if ip addresses in ip_whitelist are valid
for address in $ip_whitelist; do
    if ! [[ "$address" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
        echo -e "\n[X] IP whitelist contains one or more invalid addresses.\n"
        exit 1
    fi
done

### Replace your mailgun API, domain name, from-address and to-address in mailgun_send_alert() below ↓
### IMPORTANT: the URL ahould be https://api.eu.mailgun.net if your domain region is in EU else https://api.mailgun.net
mailgun_send_alert () {
  generate_alert=$(curl -s --user 'api:YOUR_API_KEY' \
        https://api.eu.mailgun.net/v3/YOUR_DOMAIN_NAME/messages \
       -F from='SSH LOG ALERT <ssh.log.alert@YOUR_DOMAIN_NAME>' \
       -F to=YOUR_RECEIVING_EMAIL@gmail.com \
       -F subject='SSH-LOG-ALERT - Intruder!!!' \
       -F text="Someone logged in $1 ($2) from $3: $4")

  if [[ "$generate_alert" == *"Queued"* ]]; then
      return 0
  else
      return 1
  fi
}

echo -e "\033[1m[*] SSH-LOG-ALERT is live\033[0m"

tail -n 0 -f /var/log/auth.log |
while read -r line
do
    log_entry=$(echo "$line" | grep -i "accepted")

    if [ -n "$log_entry" ]; then
        ip=$(echo "$log_entry" | cut -d " " -f 12)

        #write access log line to stdout
        echo "$log_entry"

  	    #Get origin country
        country=$(geoiplookup "$ip" | cut -d " " -f 5)
        country=$([ "$country" == 'Address' ] && echo "the Internal Network" || echo "$country")

        #Check if ip country origin in country whitelist
        if [ -n "$country_whitelist" ]; then
                #Check if geoip in country whitelist
                echo $country_whitelist | grep -w -q $country
        #Check if ip in whitelist
        elif [ -n "ip_whitelist" ]; then
            echo $ip_whitelist | grep -w -q $ip
        fi

        #Send notification if matching codition
        if (($?)); then
            server_ip=$(curl ident.me -s) #You could change this to the machine's internal ip if the sshd is not publicly accessible
            mailgun_send_alert $(hostname) "$server_ip" "$country" "$log_entry"
            if ! (($?)); then echo -e "\033[38;5;82mAlert triggered!\033[0m"; else echo -e "\033[1;91mAlert failed.\033[0m"; fi
        fi
    fi
done
