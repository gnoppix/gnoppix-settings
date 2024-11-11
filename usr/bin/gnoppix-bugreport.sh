#!/bin/bash
# Gnoppix System Report
# Dependencies - lshw, dmidecode, hdparm
# Copyright 2017 © Ralphy Rhdez <rafaelrhd3z@gmail.com>
# Website - http://unlockforus.com
# Dated - 16th April, 2017
# http://www.gnoppix.com

# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License with your
# system, in /usr/share/common-licenses/GPL-2.  If not, see
# <http://www.gnu.org/licenses/>.

# variables
_DISTRIBUTOR="Gnoppix Linux"
_APPNAME="Gnoppix System Report"
_ICON="/usr/share/icons/Papirus/24x24/apps/litesystemreport.png"		# System Report icon variable
_RUN_ICON="/usr/share/liteappsicons/litesystemreport/system-run.png"
_DATE=$(date +"%A-%d-%B-%Y-%T")
_CYEAR=$(date "+%Y")
_MYUSER=$(whoami)
_RECODE="/tmp/recode"
_HYPERVISOR="/tmp/HYPERVISOR"
_SDS="/tmp/sds"
_HDDS="/tmp/hdds"
_TMPU="/tmp/_usr"
if [ ! -f "$_TMPU" ]; then echo "$_MYUSER" > "$_TMPU"; chmod 600 "$_TMPU"; fi
_SVUSER=$(cat "$_TMPU")

# function remove temp files
rm_temp_files() {
rm -f $_HYPERVISOR
rm -f $_HDDS
rm -f $_RECODE
rm -f $_SDS
rm -f /tmp/sysreport-"${_DATE}".html
rm -f $_TMPU
}

# Script start - Ask for elevation, else exit
if [ $EUID -ne 0 ]; then
   zenity --question --ok-label="Continue" --cancel-label="Quit" --icon-name="info" --window-icon="$_ICON" --width=360 \
          --title="   $_APPNAME" --text="\n$_APPNAME is an analysis and report generator tool for $_DISTRIBUTOR.\nIt generates HTML reports on your system's hardware and software.\n\nClick <b>Quit</b> to exit now or <b>Continue</b> to proceed." 2>/dev/null
   case $? in
      0) pkexec "$0"; if [ "${PIPESTATUS[@]}" -eq "126" ]; then rm -f "$_TMPU"; fi; exit 0 ;;
      1) rm_temp_files; exit 0
   esac
fi
# set variables after auth
_MNTON=$(mount | grep -F 'on / ' | awk '{print $1}')
_INSTALLDT=$(tune2fs -l $_MNTON | grep "Filesystem created" | awk '{print $3,$4,$5,$6,$7}')

# function check for Hypervisor
dmidecode -t system | grep 'Manufacturer\|Product' > $_HYPERVISOR
hypervisor_check() {
  grep -q 'VirtualBox\|QEMU\|VMware' $_HYPERVISOR
  if [ "$?" -eq "0" ]; then box="_virtual"; else box="_metal"; fi
}
hypervisor_check
echo $box >/dev/null

# initialize html report
( echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Final//EN">'
echo '<html style="width: 98%"><head>'
echo "<title>$_DISTRIBUTOR System Report</title>"
echo '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
echo "<style>"
echo "    body    { background: #e5e5e5 }"
echo "    .title  { font: bold 130% roboto; color: #3ca2c0; padding: 20px 0 5px 0 } "
echo "    .stitle { font: bold 100% roboto; color: #3ca2c0; padding: 10px 0 10px 0 } "
echo "    .sstitle{ font: bold 100% roboto; color: #ffffff; background: #3ca2c0; } "
echo "    .field  { font: 100% roboto; color: #505050; padding: 2px; padding-left: 50px } "
echo "    .field_small  { font: 80% roboto; color: #505050; padding: 2px; padding-left: 50px } "
echo "    .value  { font: 100% roboto; color: #000000; } "
echo "    .hdd_info {font: 100% roboto; border-bottom:3px double black; border-collapse: collapse; } "
echo "    .hdd_info tr.header{border-bottom:3px double black;} "
echo "    .hdd_info th {text-align: left;}"
echo "    hr.x { color:#FFFFFF; background-color:#FFFFFF; border:1px dotted #888888; border-style:none none dotted; } "
echo "</style> "
echo '</head><body style="width: 100%">') >> /tmp/sysreport-"${_DATE}".html

# Create file and insert date
( echo '<h1 class="title">'$_DISTRIBUTOR' System Report</h1><table style="width: 100%">' && echo '<tr><td><hr class="x"/></td></tr>') >> /tmp/sysreport-"${_DATE}".html
now=$(date | awk '{print $1,$2,$3,$4,$6}')
( echo '<tr><td colspan="2" class="value">NOWDT</td></tr>' && echo '<tr><td><p></p></td></tr>') >> /tmp/sysreport-"${_DATE}".html
sed -i 's/NOWDT/Report Date: '"$now"'/g' /tmp/sysreport-"${_DATE}".html
echo '<tr><td class="field">• Hostname: '$HOSTNAME'</td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td class="field">• Installed on: '$_INSTALLDT'</td></tr>' >> /tmp/sysreport-"${_DATE}".html

# BIOS information
bios_board_info() {
echo "#✔ Gathering BIOS & Motherboard Information..." && sleep .2
echo "<tr><td class="stitle">BIOS</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">BIOS Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
dmidecode -t 0 | tail -n+7 | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# motherboard information
echo "<tr><td class="stitle">Motherboard</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Base Board Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
dmidecode -t 2 | tail -n+7 | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# chassis info
echo "<tr><td colspan="2" class="sstitle">Chassis Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
dmidecode -t 3 | tail -n+7 | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# cpu info
cpu_info() {
echo "#✔ Gathering CPU Information..." && sleep .2
echo "<tr><td class="stitle">CPU</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">CPU Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
lscpu > $_RECODE ; ed -s $_RECODE <<< $'v/^\Model name/m$\nwq\n'
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# memory info
ram_info() {
echo "#✔ Gathering Memory RAM Information..." && sleep .2
echo "<tr><td class="stitle">Memory (RAM)</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Memory (RAM) Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
if [ "$box" == "_virtual" ]; then
  echo "<tr><td class="field">Speed: <i>Not available in Virtual Machine</i></td></tr>" >> /tmp/sysreport-"${_DATE}".html
else
RAMSPEED=$(dmidecode --type 17 | grep -i speed | head -n1)
echo '<tr><td class="field">RAM RAMSPEED</td></tr>' >> /tmp/sysreport-"${_DATE}".html
sed -i 's/RAMSPEED/'"$RAMSPEED"'/g' /tmp/sysreport-"${_DATE}".html
fi
echo "<tr><td colspan="2" class="sstitle">Physical RAM Details (one section per ram slot)</td></tr>" >> /tmp/sysreport-"${_DATE}".html
if [ "$box" == "_virtual" ]; then
  echo "<tr><td class="field"><i>Not available in Virtual Machine</i></td></tr>" >> /tmp/sysreport-"${_DATE}".html
else
dmidecode -t 17 | tail -n+6 | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
sed -i '/Memory Device/ i \<tr><td><p><\/p><\/td><\/tr>' /tmp/sysreport-"${_DATE}".html
fi
}

# graphics info
graphics_info() {
echo "#✔ Collecting Graphics Chip Information..."
echo "<tr><td class="stitle">Graphics</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Graphics Chip Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
lshw -C display | tail -n+2 | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# sound info
sound_info() {
echo "#✔ Collecting Sound Information..." && sleep .2
echo "<tr><td class="stitle">Sound</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Sound Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
aplay --list-devices | tail -n+2 | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# hdd_info
hdd_info() {
echo "#✔ Collecting Hard Drive/SSD Information..." && sleep .2
echo "<tr><td class="stitle">Hard Drive/SSD</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">File Systems</td></tr>" >> /tmp/sysreport-"${_DATE}".html
df -T > $_RECODE ; sed -i 's/Mounted on/Mounted-on/g' $_RECODE

awk 'BEGIN {
    split("100,90,130,130,130,60", widths, ",")
    print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
    print "<tr class=\"header\">"
    tag = "th"
}
NR != 1{
    print "<tr class=\"field\">"
    tag = "td"
}
{
    for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
    print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Mount:</td></tr>' >> /tmp/sysreport-"${_DATE}".html
mount > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# HDD sda
fdisk -l > $_HDDS
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Disk:</td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat $_HDDS | head -n+7 > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# Device sda
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat $_HDDS | tail -n+8 | head -n+6 > $_RECODE
awk 'BEGIN {
    split("80,80,80,80,80,80,80", widths, ",")
    print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
    print "<tr class=\"header\">"
    tag = "th"
}
NR != 1{
    print "<tr class=\"field\">"
    tag = "td"
}
{
    for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
    print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# HDD sdb
if grep -q -F 'sdb' $_HDDS; then
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Disk:</td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat $_HDDS | tail -n+14 | head -n+6  > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# Device sdb
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat $_HDDS | tail -n+21 | head -n+6 > $_RECODE
awk 'BEGIN {
  split("80,80,80,80,80,80,80", widths, ",")
  print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
  print "<tr class=\"header\">"
  tag = "th"
}
NR != 1{
  print "<tr class=\"field\">"
  tag = "td"
}
{
  for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
  print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html
else :; fi

# HDD sdc
if grep -q -F 'sdb' $_HDDS; then
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Disk:</td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat $_HDDS | tail -n+27 | head -n+6  > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# Device sdc
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat $_HDDS | tail -n+34 | head -n+6 > $_RECODE
awk 'BEGIN {
split("80,80,80,80,80,80,80", widths, ",")
print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
  print "<tr class=\"header\">"
  tag = "th"
}
NR != 1{
  print "<tr class=\"field\">"
  tag = "td"
}
{
  for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
  print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html
else :; fi

# zram
if grep -q -F 'zram' $_HDDS; then
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">zRAM Disk:</td></tr>' >> /tmp/sysreport-"${_DATE}".html
grep -A100 -m1 -e 'zram0' $_HDDS > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
else :; fi

# hdd parameters
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Disk Info</td></tr>' >> /tmp/sysreport-"${_DATE}".html

if [ "$box" == "_virtual" ]; then echo "<tr><td class="field"><i>Not available in Virtual Machine</i></td></tr>" >> /tmp/sysreport-"${_DATE}".html
else
  if grep -q -F 'sda' $_HDDS; then hdparm -i /dev/sda | tail -n+2 | sed -e 's/^\s*//' -e '/^$/d' > $_SDS
    sed '
    s:^:<tr><td class="field">:;
    s:$:</td></tr>:
    ' $_SDS >> /tmp/sysreport-"${_DATE}".html
  fi
  if grep -q -F 'sdb' $_HDDS; then hdparm -i /dev/sdb | tail -n+2 | sed -e 's/^\s*//' -e '/^$/d' > $_SDS
    sed '
    s:^:<tr><td class="field">:;
    s:$:</td></tr>:
    ' $_SDS >> /tmp/sysreport-"${_DATE}".html
  fi
  if grep -q -F 'sdc' $_HDDS; then hdparm -i /dev/sdc | tail -n+2 | sed -e 's/^\s*//' -e '/^$/d' > $_SDS
    sed '
    s:^:<tr><td class="field">:;
    s:$:</td></tr>:
    ' $_SDS >> /tmp/sysreport-"${_DATE}".html
  fi
fi
}

# GROUPS info
groups_info() {
echo "#✔ Collecting Groups Information..." && sleep .2
echo "<tr><td class="stitle">Groups</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">User '"$_SVUSER"' Groups</td></tr>" >> /tmp/sysreport-"${_DATE}".html
gu=$(groups $_SVUSER | sed 's/.*://'); echo $gu | sed -e 's/^\s*//' -e '/^$/d' > $_RECODE
awk 'BEGIN {
split("80,80,80,80,80,80,80,80,80,80", widths, ",")
print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
  print "<tr class=\"header\">"
  tag = "th"
}
NR != 1{
  print "<tr>"
  tag = "td"
}
{
  for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
  print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# PCI info
pci_info() {
echo "#✔ Collecting PCI Information..." && sleep .2
echo "<tr><td class="stitle">PCI</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">PCI Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
if [ "$box" == "_virtual" ]; then echo "<tr><td class="field"><b><i>Virtual Machine PCI Information</i></b></td></tr>" >> /tmp/sysreport-"${_DATE}".html; fi
lspci > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# USB info
usb_info() {
echo "#✔ Gathering USB Information..." && sleep .2
echo "<tr><td class="stitle">USB</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">USB Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
if [ "$box" == "_virtual" ]; then echo "<tr><td class="field"><b><i>Virtual Machine USB Information</i></b></td></tr>" >> /tmp/sysreport-"${_DATE}".html; fi
lsusb > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Kernel Modules info
kernel_modules_info() {
echo "#✔ Collecting Kernel Modules Information..." && sleep .2
echo "<tr><td class="stitle">Kernel Modules</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Kernel Modules Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
lsmod > $_RECODE
awk 'BEGIN {
split("220,80,40", widths, ",")
print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
  print "<tr class=\"header\">"
  tag = "th"
}
NR != 1{
  print "<tr class=\"field_small\">"
  tag = "td"
}
{
  for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
  print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Kernel & OS info
kernel_os_info() {
echo "#✔ Collecting Kernel & OS Information..." && sleep .2
echo "<tr><td class="stitle">Kernel & Operating System</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Kernel & Operating System Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
lsb_release -dica | tail -n+2 >$_RECODE; echo "Kernel $(uname -a |cut -d" " -f3-15)" >> $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Network info
network_info() {
echo "#✔ Collecting Network Information..."
echo "<tr><td class="stitle">Network</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Network Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
ifconfig > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# network interfaces
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Network Interfaces</td></tr>' >> /tmp/sysreport-"${_DATE}".html
cat /etc/network/interfaces | tail -n+2 > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# network hardware
echo '<tr><td><p></p></td></tr>' >> /tmp/sysreport-"${_DATE}".html
echo '<tr><td colspan="2" class="sstitle">Network Hardware</td></tr>' >> /tmp/sysreport-"${_DATE}".html
lshw -short -C Network > $_RECODE && sed -i 's#H/W path#H/W-path#g' $_RECODE && sed -i '2d' $_RECODE
awk 'BEGIN {
split("120,80,80", widths, ",")
print "<tr><td style=\"padding-left: 50px;\"><table class=\"hdd_info\">"
}
NR == 1{
  print "<tr class=\"header\">"
  tag = "th"
}
NR != 1{
  print "<tr class=\"field\">"
  tag = "td"
}
{
  for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
  print "</tr>"
}
END { print "</table><p></p></td></tr>"}' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Environment info
environment_info() {
echo "#✔ Gathering Environment Variables Information..."
echo "<tr><td class="stitle">Environment Variables</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Environment Variables Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
printenv > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Software info
software_info() {
echo "#✔ Collecting Installed Software Information..." && sleep .2
echo "<tr><td class="stitle">Software Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Installed Software Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html

# software table header
dpkg --list | head -n+4 > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# software table
dpkg --list | tail -n+6 > $_RECODE
awk 'BEGIN { print "<tr><td class=\"field_small\" style=\"padding-left: 50px;\"><table>" }
     { print "<tr><td>"$1"</td><td class=\"field\">"$2"</td><td class=\"field\">"$3"</td><td class=\"field\">"$4"</td><td class=\"field\">"$5" "$6" "$7" "$8" " $9" "$10" "$11" "$12" "$13" "$14" "$15" "$16" "$17" "$18"</td></tr>" }
     END   { print "</table></td></tr>" }' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Sources info
sources_info() {
echo "#✔ Gathering Software Sources Information..." && sleep .2
echo "<tr><td class="stitle">Sources</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">Software Sources Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
grep -r --include '*.list' '^deb ' /etc/apt/sources.list /etc/apt/sources.list.d/ > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# SystemD info - systemd-analyze time
systemd_info() {
echo "#✔ Gathering SystemD Information..." && sleep .2
echo "<tr><td class="stitle">SystemD</td></tr>" >> /tmp/sysreport-"${_DATE}".html
echo "<tr><td colspan="2" class="sstitle">SystemD Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
systemd-analyze time > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:</td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# SystemD info - systemd-analyze critical-chain
echo "<tr><td colspan="2" class="sstitle">SystemD Analyze Critical-Chain Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
systemd-analyze critical-chain > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# SystemD info - systemd-analyze blame
echo "<tr><td colspan="2" class="sstitle">SystemD Analyze Blame Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
systemd-analyze blame > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html

# SystemD info - systemctl list-unit-files
echo "<tr><td colspan="2" class="sstitle">SystemD Enabled Services Information</td></tr>" >> /tmp/sysreport-"${_DATE}".html
systemctl list-unit-files --type=service | grep enabled > $_RECODE
sed '
s:^:<tr><td class="field">:;
s:$:<td></tr>:
' $_RECODE >> /tmp/sysreport-"${_DATE}".html
}

# Report selector
optreport=$(zenity --width="360" --height=620 --cancel-label="Quit" --window-icon="$_ICON" --ok-label="Create Report" --list --checklist --title="Gnoppix System Report"  \
  --text="\n     Untick options you do not want to include:\n"  \
  --column="       " --column="System Information"   --separator=":" \
   TRUE "BIOS & Motherboard" TRUE CPU TRUE "Environment Variables" TRUE Graphics TRUE Groups TRUE "Hard Drive/SSD" TRUE "Kernel Modules" TRUE "Kernel & OS" \
   TRUE "Memory RAM" TRUE Network TRUE PCI TRUE Software TRUE Sources TRUE Sound TRUE SystemD TRUE USB 2>/dev/null)

# Exit on X and Quit
if [ $? -eq "1" ]; then rm_temp_files; exit 0 ; fi

# Exit when no report parameter selected
if [ -z "$optreport" ] ; then
   zenity --info --window-icon="$_ICON" --width="280" --ok-label="Close" --timeout="5" --title="$_APPNAME" --text="\nNo parameters were selected. $_APPNAME will exit now." 2>/dev/null
   rm_temp_files; exit 0
fi

# Begin reporting information
sleep 1.5 | zenity --progress --window-icon="$_ICON" --width=365 --pulsate  --no-cancel --auto-close --title="Collecting System Information" \
                   --text="The Report may take a while to generate. Preparing..." 2>/dev/null
( IFS=":" ; for word in $optreport ; do
   case $word in
      "BIOS & Motherboard") bios_board_info ;;
      CPU) cpu_info ;;
      "Environment Variables") environment_info ;;
      Graphics) graphics_info ;;
      Groups) groups_info ;;
      "Hard Drive/SSD") hdd_info ;;
      "Kernel Modules") kernel_modules_info ;;
      "Kernel & OS") kernel_os_info ;;
      "Memory RAM") ram_info ;;
      Network) network_info ;;
      PCI) pci_info ;;
      Sound) sound_info ;;
      Software) software_info ;;
      Sources) sources_info ;;
      SystemD) systemd_info ;;
      USB) usb_info ;;
   esac
done ) | zenity --progress --window-icon="$_RUN_ICON" --width=345 --pulsate --no-cancel --auto-close --title="Collecting System Information" 2>/dev/null

# report footer
( echo "<tr><td><p></p></td></tr>" && echo '<tr><td><hr class="x"/></td></tr>'
  echo '<tr><td style="font: 70% sans-serif;"><a>2002-'$_CYEAR'© '$_DISTRIBUTOR' Free Operating System</a></td></tr>' && echo "<tr><td><p></p></td></tr>"
  echo "</html>" ) >> /tmp/sysreport-"${_DATE}".html
  # show report results
_ANS=$(zenity --title="System Report" --text-info --window-icon="$_ICON" --width="880" --height="540" \
              --extra-button="Save to Desktop" --ok-label="Save..." --cancel-label="Quit" --html --filename='/tmp/sysreport-'"${_DATE}"'.html' 2>/dev/null); _OPT=$(echo $?)
if [[ "$_ANS" =~ "Save to Desktop" ]]; then sudo -u ${SUDO_USER:-$_SVUSER} cp /tmp/sysreport-"${_DATE}".html /home/$_SVUSER/Desktop/; rm_temp_files; exit 0 ; fi
case $_OPT in
  0) szSavePath=$(zenity --title="    Save System Report" --width=550 --height=380 --file-selection --filename=/home/$_SVUSER/sysreport-"${_DATE}".html \
                         --file-filter='*.html' --file-filter='All files | *' --save --confirm-overwrite 2>/dev/null)
      if [ "$?" -eq "0" ]; then sudo -u ${SUDO_USER:-$_SVUSER} cp /tmp/sysreport-"${_DATE}".html $szSavePath; rm_temp_files; else rm_temp_files; exit 0 ; fi ;;
  1) rm_temp_files; exit 0 ;;
esac
done
exit 0
