#!/bin/bash
###################################################
#
# HostGator Brasil LTDA - 2024
#
###################################################
# Author:
#
# Fabrício Wonzoski <fabricio.wonzoski@newfold.com>
# Jr Advanced Support Analyst (N2)
#
###################################################
#
# Script to free up disk quota temporarily
#
###################################################

# Definindo variáveis
b=$1
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'
PLANO=$(whmapi1 accountsummary user=$b | grep plan | awk -F":" '{print $2}' | sed 's/^[ \t]*//')
VALOR=$(whmapi1 getpkginfo pkg="$PLANO" | egrep '^    QUOTA' | awk '{print $2}')

ajuste_quota() {
local a=$1

#Verifica se o pacote criado
if [ $VALOR = '~' ]; then
                echo -e "\n ${RED}Algo está errado! O pacote atual do usuário ${BOLD}"$b" ${NC}${RED}está definido como ${BOLD}"$PLANO"${NC}${RED} o qual tem a cota de disco ilimitada. Verifique... ${NC}"
            else
                NVALOR=$(($VALOR + 10000))
                COTATUAL=$(whmapi1 accountsummary user=$b | grep disklimit | awk '{print $2}' | tr -d 'M')
                if [ $COTATUAL == $VALOR ]; then
                    whmapi1 editquota user=$b quota=$NVALOR > /dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "\n Cota de disco do usuário ${GREEN}"$b"${NC} ajustada com sucesso para ${GREEN}"$NVALOR "MB${GREEN}${NC}"
                        eval $a
                        (sleep 172800 ; whmapi1 changepackage user=$b pkg=$(whmapi1 accountsummary user=$b | grep plan | awk '{print $2}')) > /dev/null 2>&1 &
                        disown
                    fi
                else
                    echo -e "\n O valor da cota de disco atual ${RED}${BOLD}"$COTATUAL" MB${NC} está diferente da padrão do plano ${RED}${BOLD}"$PLANO"${NC} que é de ${NC}${RED}${BOLD}"$VALOR" MB${NC}, deseja continuar mesmo assim? ${BOLD}[S/N]${NC}"
                    read -r -n 1 key
                    echo -e "\n"
                    if [[ $key == [Ss] ]]; then
                        whmapi1 editquota user=$b quota=$NVALOR > /dev/null 2>&1
                        if [ $? -eq 0 ]; then
                           echo -e "\n Cota de disco do usuário ${GREEN}"$b"${NC} ajustada com sucesso para ${GREEN}"$NVALOR "MB${GREEN}${NC}"
                           eval $a
                           (sleep 172800 ; whmapi1 changepackage user=$b pkg=$(whmapi1 accountsummary user=$b | grep plan | awk '{print $2}')) > /dev/null 2>&1 &
                           disown
         fi
      fi
   fi
fi

}

if [ "$HOSTNAME" != *hostgator* ] && [ ! -f "/opt/hgctrl/.zengator" ]; then
    echo -e "\n ${RED}Comando não disponível para este tipo de plano! ${NC} \n"
else
if [ -n "$b"  ]; then
if awk '{print $2}' /etc/userdomains | grep -qw $b ; then
    if egrep -q "^$b:" /var/log/quota_user.log; then
        echo -e "\n Já foi disponibilizado mais cota de disco para o usuário ${RED}${BOLD}"$b"${NC} em ${RED}${BOLD}"$(egrep "^$b:" /var/log/quota_user.log | awk -F":" '{print $2}')"${NC}, deseja
continuar? ${BOLD}[S/N]${NC}"
        read -r -n 1 key
        echo -e "\n"
        if [[ $key == [Ss] ]]; then
            AJUSTE="sed -i '/'$b:'/ { s/.*/'$b:$(date +'%d-%m-%Y')'/ }' /var/log/quota_user.log";
            ajuste_quota "$AJUSTE"
        fi
        else AJUSTE="echo $b:$(date +'%d-%m-%Y') >> /var/log/quota_user.log" ; ajuste_quota "$AJUSTE"
fi
        else echo -e "\n ${RED}O usuário ${RED}${BOLD}"$b"${NC}${RED} não existe neste servidor${NC}"
fi
        else echo -e "\n ${RED}Digite um usuário!${NC}"
fi
fi
