#!/bin/bash

# MonsterVps Installation Script - mastermind
module="$(pwd)/module"
rm -rf ${module}

# Try to download module, if fails use local module
if ! wget -O ${module} "https://raw.githubusercontent.com/mastermind/Herramientas/main/module/module" &>/dev/null; then
    # Use local module system
    if [[ -f "$(pwd)/module.sh" ]]; then
        cp "$(pwd)/module.sh" ${module}
    else
        echo "Error: Module system not found"
        exit 1
    fi
fi

[[ ! -e ${module} ]] && exit
chmod +x ${module} &>/dev/null
source ${module}

CTRL_C(){
  rm -rf ${module}; exit
}

if [[ ! $(id -u) = 0 ]]; then
  clear
  msg -bar
  print_center -ama "ERROR DE EJECUCION"
  msg -bar
  print_center -ama "DEVE EJECUTAR DESDE EL USUSRIO ROOT"
  msg -bar
  CTRL_C
fi

trap "CTRL_C" INT TERM EXIT

MonsterVps="/etc/MonsterVps" && [[ ! -d ${MonsterVps} ]] && mkdir ${MonsterVps}
ADM_inst="${MonsterVps}/install" && [[ ! -d ${ADM_inst} ]] && mkdir ${ADM_inst}
tmp="${MonsterVps}/tmp" && [[ ! -d ${tmp} ]] && mkdir ${tmp}
SCPinstal="$HOME/install"

#rm -rf /etc/localtime &>/dev/null
#ln -s /usr/share/zoneinfo/America/Argentina/Tucuman /etc/localtime &>/dev/null
cp -f $0 ${MonsterVps}/install.sh
rm $(pwd)/$0 &> /dev/null
if [[ $(which install-LIC) = "" ]]; then
  wget -O /usr/bin/install-LIC 'https://github.com/mastermind/Rufu-LIC/raw/main/install-LIC'; chmod +x /usr/bin/install-LIC &>/dev/null
fi
install-LIC
[[ $? = 1 ]] && exit

stop_install(){
  title "INSTALACION CANCELADA"
  exit
 }

time_reboot(){
  print_center -ama "REINICIANDO VPS EN $1 SEGUNDOS"
  REBOOT_TIMEOUT="$1"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
     print_center -ne "-$REBOOT_TIMEOUT-\r"
     sleep 1
     : $((REBOOT_TIMEOUT--))
  done
  reboot
}

fixDeb12Ubu24(){
  if ! command -v ldd &>/dev/null; then
      echo "Error: ldd no está instalado."
      echo "Por lo que no se puede aplicar el fix debian12/ubuntu24"
  else
        _glibc=$(ldd --version|head -1|grep -o '[0-9]\+\.[0-9]\+'|sed 's/\.//g'|head -1)
  
        if [[ -n $_glibc && $_glibc -ge 235 ]]; then
                wget -O /root/fix https://github.com/mastermind/MonsterVps/raw/refs/heads/main/fix && chmod 755 /root/fix && /root/fix
        else
            echo "Glibc es inferior a 2.35 o no se pudo determinar la versión."
            echo "Por lo que no se puede aplicar el fix debian12/ubuntu24"
        fi
  fi
}

repo_install(){
  link="https://raw.githubusercontent.com/mastermind/MonsterVps/main/Repositorios/$VERSION_ID.list"
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|20.10*|21.04*|21.10*|22.04*) [[ ! -e /etc/apt/sources.list.back ]] && cp /etc/apt/sources.list /etc/apt/sources.list.back
                                                                    wget -O /etc/apt/sources.list ${link} &>/dev/null;;
    12*|24.04*) fixDeb12Ubu24;;
  esac
}

dependencias(){
  soft="sudo bsdmainutils zip unzip ufw curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat sqlite3 libsqlite3-dev locales"

  for install in $soft; do
    leng="${#install}"
    puntos=$(( 21 - $leng))
    pts="."
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    msg -nazu "      instalando $install $(msg -ama "$pts")"
    if apt install $install -y &>/dev/null ; then
      msg -verd "INSTALL"
    else
      msg -verm2 "FAIL"
      sleep 2
      del 1
      if [[ $install = "python" ]]; then
        pts=$(echo ${pts:1})
        msg -nazu "      instalando python2 $(msg -ama "$pts")"
        if apt install python2 -y &>/dev/null ; then
          [[ ! -e /usr/bin/python ]] && ln -s /usr/bin/python2 /usr/bin/python
          msg -verd "INSTALL"
        else
          msg -verm2 "FAIL"
        fi
        continue
      fi
      print_center -ama "aplicando fix a $install"
      dpkg --configure -a &>/dev/null
      sleep 2
      del 1
      msg -nazu "      instalando $install $(msg -ama "$pts")"
      if apt install $install -y &>/dev/null ; then
        msg -verd "INSTALL"
      else
        msg -verm2 "FAIL"
      fi
    fi
  done
}

verificar_arq(){
  unset ARQ
  case $1 in
    menu|menu_inst.sh|tool_extras.sh|chekup.sh|bashrc)ARQ="${MonsterVps}";;
    MonsterVps)ARQ="/usr/bin";;
    message.txt)ARQ="${tmp}";;
    *)ARQ="${ADM_inst}";;
  esac
  mv -f ${SCPinstal}/$1 ${ARQ}/$1
  chmod +x ${ARQ}/$1
}

error_fun(){
  msg -bar3
  #print_center -verm "ERROR de enlace VPS<-->GENERADOR"
  print_center -verm "Falla aldescargar $1"
  print_center -ama "Reportar con el administrador @Rufu99"
  msg -bar3
  [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
  exit
}

post_reboot(){
  echo 'clear; sleep 2; /etc/MonsterVps/install.sh --continue' >> /root/.bashrc
  title "INSTALADOR MonsterVps"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!"
  msg -bar
}

install_start(){
  title "INSTALADOR MonsterVps"
  print_center -ama "A continuacion se actualizaran los paquetes\ndel systema. Esto podria tomar tiempo,\ny requerir algunas preguntas\npropias de las actualizaciones."
  msg -bar3
  read -rp "$(msg -verm2 " Desea continuar? [S/N]:") " -e -i S opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  title "INSTALADOR MonsterVps"
  print_center -ama 'Esto modificara la hora y fecha automatica\nsegun la Zona horaria establecida.'
  msg -bar
  read -rp "$(msg -ama " Modificar la zona horaria? [S/N]:") " -e -i N opcion
  [[ "$opcion" != @(n|N) ]] && source <(curl -sSL "https://raw.githubusercontent.com/mastermind/MonsterVps/main/online/timeZone.sh")
  title "INSTALADOR MonsterVps"
  repo_install
  mysis=$(echo "$VERSION_ID"|cut -d '.' -f1)
  #[[ ! $mysis = '22' ]] && add-apt-repository -y ppa:ondrej/php &>/dev/null
  apt update -y; apt upgrade -y
  [[ "$VERSION_ID" = '9' ]] && source <(curl -sL https://deb.nodesource.com/setup_10.x)
}

install_continue(){
  title "INSTALADOR MonsterVps"
  print_center -ama "$PRETTY_NAME"
  print_center -verd "INSTALANDO DEPENDENCIAS"
  msg -bar3
  dependencias
  msg -bar3
  print_center -azu "Removiendo paquetes obsoletos"
  apt autoremove -y &>/dev/null
  [[ "$VERSION_ID" = '9' ]] && apt remove unscd -y &>/dev/null
  sleep 2
  tput cuu1 && tput dl1
  print_center -ama "si algunas de las dependencias falla!!!\nal terminar, puede intentar instalar\nla misma manualmente usando el siguiente comando\napt install nom_del_paquete"
  enter
}

source /etc/os-release; export PRETTY_NAME

while :
do
  case $1 in
    -s|--start)install_start; post_reboot; time_reboot "15";;
    -c|--continue)sed -i '/Rufu/d' /root/.bashrc
                  install_continue
                  break;;
    -u|--update)install_start
                rm -rf /etc/MonsterVps/tmp/style
                install_continue
                break;;
    -t|--test)break;;
    *)exit;;
  esac
done

title "INSTALADOR MonsterVps"
fun_ip

msg -ne " Verificando Datos: "
cd $HOME

arch='MonsterVps
bashrc
budp.sh
cert.sh
chekup.sh
chekuser.sh
confDNS.sh
domain.sh
filebrowser.sh
limitador.sh
menu
menu_inst.sh
openvpn.sh
PDirect.py
PGet.py
POpen.py
PPriv.py
PPub.py
sockspy.sh
squid.sh
swapfile.sh
tcpbbr.sh
tool_extras.sh
userHWID
userSSH
userTOKEN
userV2ray.sh
userWG.sh
v2ray.sh
wireguard.sh
ws-cdn.sh
WS-Proxy.js'

lisArq="https://raw.githubusercontent.com/mastermind/MonsterVps/refs/heads/main/old"

ver=$(curl -sSL "https://raw.githubusercontent.com/mastermind/MonsterVps/main/vercion")
echo "$ver" > ${MonsterVps}/vercion
echo -e "Idioma=es_ES.utf8\nRutaLocales=locale" > ${MonsterVps}/lang.ini

title -ama '[Proyect by @Rufu99]'
print_center -ama 'INSTALANDO SCRIPT MonsterVps'
sleep 2; del 1

[[ ! -d ${SCPinstal} ]] && mkdir ${SCPinstal}
print_center -ama 'Descarga de archivos.....'

for arqx in $(echo $arch); do
 # wget --no-check-certificate -O ${SCPinstal}/${arqx} ${lisArq}/${arqx} > /dev/null 2>&1 && {
  wget -O ${SCPinstal}/${arqx} ${lisArq}/${arqx} > /dev/null 2>&1 && {
    verificar_arq "${arqx}"
  } || {
    del 1
    print_center -verm2 'Instalacion fallida de $arqx'
    sleep 2s
    error_fun "${arqx}"
  }
done

url='https://github.com/mastermind/MonsterVps/raw/main/Utils'

autoStart="${MonsterVps}/bin" && [[ ! -d $autoStart ]] && mkdir $autoStart
varEntorno="${MonsterVps}/sbin" && [[ ! -d $varEntorno ]] && mkdir $varEntorno

cat <<EOF>$varEntorno/ls-cmd
#!/bin/bash
echo 'menu'
ls /etc/MonsterVps/sbin|sed 's/ /\n/'
EOF
chmod +x $varEntorno/ls-cmd

wget --no-cache -O $autoStart/autoStart "$url/autoStart/autoStart" &>/dev/null; chmod +x $autoStart/autoStart
wget --no-cache -O $autoStart/auto-update "$url/auto-update/auto-update" &>/dev/null; chmod +x $autoStart/auto-update

wget --no-cache -O ${MonsterVps}/install/udp-custom "$url/udp-custom/udp-custom" &>/dev/null; chmod +x ${MonsterVps}/install/udp-custom
wget --no-cache -O ${MonsterVps}/install/psiphon-manager "$url/psiphon/psiphon-manager" &>/dev/null; chmod +x ${MonsterVps}/install/psiphon-manager
wget --no-cache -O ${varEntorno}/dropBear "$url/dropBear/dropBear" &>/dev/null; chmod +x ${varEntorno}/dropBear

wget --no-cache -O ${varEntorno}/protocolsUDP "$url/protocolsUDP/protocolsUDP" &>/dev/null;           chmod +x ${varEntorno}/protocolsUDP 
wget --no-cache -O ${varEntorno}/udprequest   "$url/protocolsUDP/udprequest/udprequest" &>/dev/null;  chmod +x ${varEntorno}/udprequest
wget --no-cache -O ${varEntorno}/udpcustom    "$url/protocolsUDP/udpcustom/udpcustom" &>/dev/null;    chmod +x ${varEntorno}/udpcustom
#wget --no-cache -O ${varEntorno}/udp-zivpn    "$url/protocolsUDP/zivpn/udp-zivpn" &>/dev/null;        chmod +x ${varEntorno}/udp-zivpn
wget --no-cache -O ${varEntorno}/udp-udpmod   "$url/protocolsUDP/udpmod/udp-udpmod" &>/dev/null;      chmod +x ${varEntorno}/udp-udpmod
wget --no-cache -O ${varEntorno}/Stunnel      "$url/Stunnel/Stunnel" &>/dev/null;                     chmod +x ${varEntorno}/Stunnel
wget --no-cache -O ${varEntorno}/Slowdns      "$url/SlowDNS/Slowdns" &>/dev/null;                     chmod +x ${varEntorno}/Slowdns
wget --no-cache -O ${varEntorno}/cmd          "$url/mine_port/cmd" &>/dev/null;                       chmod +x ${varEntorno}/cmd
wget --no-cache -O ${varEntorno}/epro-ws      "$url/epro-ws/epro-ws" &>/dev/null;                     chmod +x ${varEntorno}/epro-ws
wget --no-cache -O ${varEntorno}/socksPY      "$url/socksPY/socksPY" &>/dev/null;                     chmod +x ${varEntorno}/socksPY

wget --no-cache -O ${varEntorno}/monitor      "$url/user-manager/monitor/monitor" &>/dev/null;        chmod +x ${varEntorno}/monitor
wget --no-cache -O ${varEntorno}/online       "$url/user-manager/monitor/online/online" &>/dev/null;  chmod +x ${varEntorno}/online
wget --no-cache -O ${varEntorno}/user-info    "$url/user-managers/user-info" &>/dev/null;             chmod +x ${varEntorno}/user-info
wget --no-cache -O ${varEntorno}/aToken-mng   "$url/aToken/aToken-mng" &>/dev/null;                   chmod +x ${varEntorno}/aToken-mng
wget --no-cache -O ${varEntorno}/makeUser     "$url/user-managers/makeUser" &>/dev/null;              chmod +x ${varEntorno}/makeUser
wget --no-cache -O ${varEntorno}/genssl       "$url/genCert/genssl" &>/dev/null;                      chmod +x ${varEntorno}/genssl
wget --no-cache -O ${autoStart}/sql           "$url/Csqlite/sql" &>/dev/null;                         chmod +x ${autoStart}/sql
wget --no-cache -O ${varEntorno}/banner       "$url/banner/banner" &>/dev/null;                       chmod +x ${varEntorno}/banner
wget --no-cache -O ${varEntorno}/monitor-m    "$url/user-manager/monitor/monitor-m/monitor-m" &>/dev/null; chmod +x ${varEntorno}/monitor-m

wget --no-cache -O ${varEntorno}/userSSH      "$url/user-managers/userSSH/userSSH" &>/dev/null;       chmod +x ${varEntorno}/userSSH
wget --no-cache -O ${varEntorno}/userHWID     "$url/user-managers/userHWID/userHWID" &>/dev/null;     chmod +x ${varEntorno}/userHWID
wget --no-cache -O ${varEntorno}/userTOKEN    "$url/user-managers/userTOKEN/userTOKEN" &>/dev/null;   chmod +x ${varEntorno}/userTOKEN

wget --no-cache -O ${autoStart}/limit    "$url/user-managers/limitador/limit" &>/dev/null;   chmod +x ${autoStart}/limit
${autoStart}/limit

wget --no-cache -O /etc/MonsterVps/uninstall "https://github.com/mastermind/MonsterVps/raw/main/uninstall" &>/dev/null; chmod +x /etc/MonsterVps/uninstall

if [[ -e $autoStart/autoStart ]]; then
  $autoStart/autoStart -e /etc/MonsterVps/autoStart
fi

#profileDir="/etc/profile.d" && [[ ! -d ${profileDir} ]] && mkdir ${profileDir}
#echo '#!/bin/bash
#export PATH="$PATH:/etc/MonsterVps/sbin"' > /etc/profile.d/rufu.sh
#chmod +x /etc/profile.d/rufu.sh
rm -rf /etc/profile.d/rufu.sh

sbinList=$(ls ${varEntorno})
for i in `echo $sbinList`; do
  ln -s ${varEntorno}/$i /usr/bin/$i
done

del 1

print_center -verd 'Instalacion completa'
sleep 2s
rm $HOME/lista-arq
[[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
rm -rf /usr/bin/menu
rm -rf /usr/bin/adm
ln -s /usr/bin/MonsterVps /usr/bin/menu
ln -s /usr/bin/MonsterVps /usr/bin/adm
ln -s /etc/MonsterVps/reseller /etc/MonsterVps/tmp/message.txt
sed -i '/Rufu/d' /etc/bash.bashrc
sed -i '/Rufu/d' /root/.bashrc
echo '[[ -e /etc/MonsterVps/bashrc ]] && source /etc/MonsterVps/bashrc' >> /etc/bash.bashrc
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LANGUAGE=en LC_ALL=en_US.UTF-8
echo -e "LANG=en_US.UTF-8\nLANGUAGE=en\nLC_ALL=en_US.UTF-8" > /etc/default/locale
[[ ! $(cat /etc/shells|grep "/bin/false") ]] && echo -e "/bin/false" >> /etc/shells
clear
title "-- MonsterVps INSTALADO --"

mv -f ${module} /etc/MonsterVps/module
time_reboot "10"
