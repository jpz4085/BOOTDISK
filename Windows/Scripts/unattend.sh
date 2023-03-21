#!/usr/bin/env bash

#  unattend.sh - Build a Windows answer file.
#  
#
#  Created by Joseph P. Zeller.

Unsupported="$1"
Localize="$2"
BypassNRO="$3"
OOBE="$4"
SetTimeZone="$5"
UserAccounts="$6"
SkipWIFISetup="$7"
NoDataCollection="$8"
NoAutoEncrypt="$9"
LoginName="${10}"
FullName="${11}"
Description="${12}"

system=`uname`
if   [[ $system == "Darwin" ]]; then
     Lang=$(defaults read -g AppleLanguages  | sed 's/[(") ]//g' | grep -v -e '^$')
elif [[ $system == "Linux" ]]; then
     Lang=$(echo $LANG | sed 's/_/-/g' | cut -f1 -d".")
fi

if [[ $SetTimeZone == "true" ]]; then
   TimeZoneName=$(pwsh -Command "Get-TimeZone | grep StandardName | sed 's/.*: //' | Tee-Object -Variable TimeZoneName")
fi

printf "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<unattend xmlns=\"urn:schemas-microsoft-com:unattend\">\r\n"
if [[ $Unsupported == "true" || $Localize == "true" ]]; then
   printf " <settings pass=\"windowsPE\">\r\n"
   if [[ $Localize == "true" ]]; then
      cat Microsoft-Windows-International-Core-WinPE.xml
      printf "%3s<SetupUILanguage>\r\n"
      printf "%4s<UILanguage>%s</UILanguage>\r\n" '' "$Lang"
      printf "%3s</SetupUILanguage>\r\n"
      printf "%3s<InputLocale>%s</InputLocale>\r\n" '' "$Lang"
      printf "%3s<SystemLocale>%s</SystemLocale>\r\n" '' "$Lang"
      printf "%3s<UILanguage>%s</UILanguage>\r\n" '' "$Lang"
      printf "%3s<UILanguageFallback>%s</UILanguageFallback>\r\n" '' "$Lang"
      printf "%3s<UserLocale>%s</UserLocale>\r\n" '' "$Lang"
      printf "  </component>\r\n"
   fi
   cat Microsoft-Windows-Setup.xml
   if [[ $Unsupported == "true" ]]; then
      cat Disable-Hardware-Requirements.xml
   fi
   printf "%3s<UserData>\r\n%4s<ProductKey>\r\n%5s<Key></Key>\r\n"
   printf "%4s</ProductKey>\r\n%4s<AcceptEula>true</AcceptEula>\r\n"
   printf "%3s</UserData>\r\n  </component>\r\n </settings>\r\n"
fi
if [[ $BypassNRO == "true" ]]; then
    printf " <settings pass=\"specialize\">\r\n"
    cat Microsoft-Windows-Deployment.xml
    printf "  </component>\r\n </settings>\r\n"
fi
if [[ $OOBE == "true" || $SetTimeZone == "true" || $UserAccounts == "true" ||
   $Localize == "true" || $NoAutoEncrypt == "true" ]]; then
   printf " <settings pass=\"oobeSystem\">\r\n"
   if [[ $OOBE == "true" || $SetTimeZone == "true" || $UserAccounts == "true" ]]; then
      cat Microsoft-Windows-Shell-Setup.xml
      if [[ $OOBE == "true" ]]; then
         printf "%3s<OOBE>\r\n"
         if [[ $SkipWIFISetup == "true" ]]; then
            printf "%4s<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>\r\n"
         fi
         if [[ $NoDataCollection == "true" ]]; then
            printf "%4s<ProtectYourPC>3</ProtectYourPC>\r\n"
         fi
         printf "%3s</OOBE>\r\n"
      fi
      if [[ $SetTimeZone == "true" ]]; then
         printf "%3s<TimeZone>%s</TimeZone>\r\n" '' "$TimeZoneName"
      fi
      if [[ $UserAccounts == "true" ]]; then
         printf "%3s<UserAccounts>\r\n%4s<LocalAccounts>\r\n"
         printf "%5s<LocalAccount wcm:action=\"add\">\r\n"
         printf "%6s<Password>\r\n%7s<Value>UABhAHMAcwB3AG8AcgBkAA==</Value>\r\n"
         printf "%7s<PlainText>false</PlainText>\r\n%6s</Password>\r\n"
         printf "%6s<Description>%s</Description>\r\n" '' "$Description"
         printf "%6s<DisplayName>%s</DisplayName>\r\n" '' "$FullName"
         printf "%6s<Group>Administrators;Power Users</Group>\r\n" ''
         printf "%6s<Name>%s</Name>\r\n" '' "$LoginName"
         printf "%5s</LocalAccount>\r\n%4s</LocalAccounts>\r\n%3s</UserAccounts>\r\n"
         printf "%3s<FirstLogonCommands>\r\n%4s<SynchronousCommand wcm:action=\"add\">\r\n%5s<Order>1</Order>\r\n"
         printf "%5s<CommandLine>net user %s /logonpasswordchg:yes</CommandLine>\r\n" '' "$LoginName"
         printf "%5s<Description>Change blank password at next logon.</Description>\r\n"
         printf "%4s</SynchronousCommand>\r\n%3s</FirstLogonCommands>\r\n"
      fi
      printf "  </component>\r\n"
   fi
   if [[ $Localize == "true" ]]; then
      cat Microsoft-Windows-International-Core.xml
      printf "%3s<InputLocale>%s</InputLocale>\r\n" '' "$Lang"
      printf "%3s<SystemLocale>%s</SystemLocale>\r\n" '' "$Lang"
      printf "%3s<UILanguage>%s</UILanguage>\r\n" '' "$Lang"
      printf "%3s<UILanguageFallback>%s</UILanguageFallback>\r\n" '' "$Lang"
      printf "%3s<UserLocale>%s</UserLocale>\r\n" '' "$Lang"
      printf "  </component>\r\n"
   fi
   if [[ $NoAutoEncrypt == "true" ]]; then
      cat Microsoft-Windows-SecureStartup-FilterDriver.xml
      printf "%3s<PreventDeviceEncryption>true</PreventDeviceEncryption>\r\n"
      printf "  </component>\r\n"
   fi
   printf " </settings>\r\n"
fi
printf "</unattend>\r\n"
