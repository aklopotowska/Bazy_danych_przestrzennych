
#Created on 12.12.2021 by Anna Kłopotowska (402868)

# DATE
$date = Get-Date 
${TIMESTAMP}  = "{0:MM-dd-yyyy}" -f ($date) 


# .log FILE
$script = "C:\Users\anklo\OneDrive\Pulpit\BDP\cw8.ps1"
$log = "C:\Users\anklo\OneDrive\Pulpit\BDP\\Cwiczenie8_${TIMESTAMP}.log"

$script_log = Get-ItemProperty $script | Format-Wide -Property CreationTime
"## LAB 8 ##`n`nScript creation date:" > $log
$script_log >> $log

# Customers_Nov2021.zip DOWNLOAD

$url = "https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip"
$file = "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.zip"

Invoke-WebRequest -Uri $url -OutFile $file

$date = Get-Date 
$date, " : Customers_Nov2021.zip download: Successful!" >> $log


# UNZIP FILE

$WinRAR = "C:\Program Files\WinRAR\WinRAR.exe"
$pass = "agh"
Set-Location "C:\Users\anklo\OneDrive\Pulpit\BDP"

Start-Process "$WinRAR" -ArgumentList "x -y `"$file`" -p$pass"

$date = Get-Date 
$date, " : Unzip file : Successful!" >> $log


# DATA VALIDATION

$IndexNo = "402868"
$file_1 = Get-Content "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.csv"

#searching for empty lines
$correct_file = for($i = 0; $i -lt $file_1.Count; $i++)
                 {
                  if($file_1[$i] -ne "")
                     {
                         $file_1[$i]  
                     }
                 } 

$correct_file[0] > "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.bad_${TIMESTAMP}"

#comparing input file with the Customers_old.csv file
$file_2 = Get-Content "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_old.csv"
for($i = 1; $i -lt $correct_file.Count; $i++)
{
  for($j = 0; $j -lt $file_2.Count; $j++)
    {
       if($correct_file[$i] -eq $file_2[$j])
         {
             $correct_file[$i] >> "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.bad_${TIMESTAMP}"
             $correct_file[$i] = $null
          }
   }
 } 

#correct data
$correct_file > "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.csv" 

$date = Get-Date 
$date, " : validation : Successful!" >> $log


# SQL

Set-Location 'C:\Program Files\PostgreSQL\13\bin\'

#PostgreSQL login info
$env:USER = "lab8"
$env:PGPASSWORD = 'lab8'
$env:DATABASE = "lab8"
$env:NEWDATABASE = "customers"
$env:TABLE = "CUSTOMERS_$IndexNo"
$env:SERVER  ="PostgreSQL 13"
$env:PORT = "5432"

#creating database and table
./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "DROP TABLE IF EXISTS $env:TABLE"
./psql.exe -U lab8 -d $env:DATABASE -w -c "DROP DATABASE IF EXISTS $env:NEWDATABASE"
./psql.exe -U lab8 -d $env:DATABASE -w -c "CREATE DATABASE $env:NEWDATABASE"
./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "CREATE TABLE IF NOT EXISTS $env:TABLE (first_name VARCHAR(100), last_name VARCHAR(100) PRIMARY KEY, email VARCHAR(100), lat VARCHAR(100) NOT NULL, long VARCHAR(100) NOT NULL)"

$date = Get-Date 
$date, " : creating database and table : Successful!" >> $log


#LOADING DATA

# , -> ','
$correct_file_2 = $correct_file -replace ",", "','"

#inserting data to table
for($i=1; $i -lt $correct_file_2.Count; $i++)
{
    $correct_file_2[$i] = "'" + $correct_file_2[$i] + "'"
    $read = $correct_file_2[$i]
    ./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "INSERT INTO $env:TABLE (first_name, last_name, email, lat, long) VALUES($read)"
}

#show table
./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "SELECT * FROM $env:TABLE"

$date = Get-Date 
$date, " : loading data : Successful!" >> $log



# moving file to PROCESSED

#creating PROCESSED
New-Item -Path 'C:\Users\anklo\OneDrive\Pulpit\BDP\PROCESSED' -ItemType Directory

Set-Location 'C:\Users\anklo\OneDrive\Pulpit\BDP'

#moving and renaming
Move-Item -Path "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.csv" -Destination "C:\Users\anklo\OneDrive\Pulpit\BDP\PROCESSED" -PassThru -ErrorAction Stop
Rename-Item -Path "C:\Users\anklo\OneDrive\Pulpit\BDP\PROCESSED\Customers_Nov2021.csv" "${TIMESTAMP}_Customers_Nov2021.csv"

$date = Get-Date 
$date, " : moving file to PROCESSED : Successful!" >> $log


# SENDING FIRST E-MAIL

$correct_file = Get-Content "C:\Users\anklo\OneDrive\Pulpit\BDP\PROCESSED\${TIMESTAMP}_Customers_Nov2021.csv"
$incorrect_file = Get-Content "C:\Users\anklo\OneDrive\Pulpit\BDP\Customers_Nov2021.bad_${TIMESTAMP}"

$all_lines = $file_1.Count
$no_empty_lines = $correct_file.Count -1
$duplicates = $incorrect_file.Count -1
$customers_data = $correct_file.Count -1


$my_email = "projektyaghania@gmail.com" 
$SMTP= "smtp.gmail.com"
$To = "projektyaghania@gmail.com"
$Sub = "CUSTOMERS LOAD - ${TIMESTAMP}"
$Bod = "Number of rows in downloaded file: $all_lines`n
Number of correct rows: $no_empty_lines`n
Number of duplicates: $duplicates`n 
Number of inserted records: $customers_data `n"

$Creds = (Get-Credential -Credential $my_email)

Send-MailMessage -To $my_email -From $my_email -Subject $Sub -Body $Bod -SmtpServer $SMTP -Credential $Creds -UseSsl -Port 587 -DeliveryNotificationOption never

$date = Get-Date 
$date, " : sending first e-mail : Successful!" >> $log


# FINDING THE BEST CUSTOMERS

New-Item -Path 'C:\Users\anklo\OneDrive\Pulpit\BDP\sql_query.txt' -ItemType File

#query
Set-Content -Path 'C:\Users\anklo\OneDrive\Pulpit\BDP\sql_query.txt' -Value " 
alter table customers_402868 alter column lat type double precision using lat::double precision;
alter table customers_402868 alter column long type double precision using long::double precision;

SELECT first_name, last_name  INTO best_customers_402868 FROM customers_402868
        WHERE ST_DistanceSpheroid( 
        ST_Point(lat, long), ST_Point(41.39988501005976, -75.67329768604034),
        'SPHEROID[""WGS 84"",6378137,298.257223563]') <= 50000;"
        

Set-Location 'C:\Program Files\PostgreSQL\13\bin\'
$NEWTABLE = "BEST_CUSTOMERS_402868"
./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "DROP TABLE IF EXISTS $NEWTABLE"


./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "CREATE EXTENSION postgis"
./psql.exe -U lab8 -d $env:NEWDATABASE -w -f "C:\Users\anklo\OneDrive\Pulpit\BDP\sql_query.txt"


$date = Get-Date 
$date, " : SQL query : Successful!" >> $log


# TABLE EXPORT

$table_tmp = ./psql.exe -U lab8 -d $env:NEWDATABASE -w -c "SELECT * FROM $NEWTABLE" 
$table_tmp
$tab = @()

for ($i=2; $i -lt $table_tmp.Count-2; $i++)
{
    $data = New-Object -TypeName PSObject
    $data  | Add-Member -Name 'first_name' -MemberType Noteproperty -Value $table_tmp[$i].Split( "|")[0]
    $data  | Add-Member -Name 'last_name' -MemberType Noteproperty -Value $table_tmp[$i].Split( "|")[1]
    $tab += $data 
}

#exporting to csv
$tab | Export-Csv -Path "C:\Users\anklo\OneDrive\Pulpit\BDP\$NEWTABLE.csv" -NoTypeInformation

$date = Get-Date 
$date, " : table export : Successful!" >> $log


# FILE COMPRESSING

Compress-Archive -Path "C:\Users\anklo\OneDrive\Pulpit\BDP\$NEWTABLE.csv" -DestinationPath "C:\Users\anklo\OneDrive\Pulpit\BDP\$NEWTABLE.zip"


$date = Get-Date 
$date, " : file compressing : Successful!" >> $log


# SENDING SECOND E-MAIL

Get-ItemProperty "C:\Users\anklo\OneDrive\Pulpit\BDP\$NEWTABLE.csv" | Format-Wide -Property CreationTime > "C:\Users\anklo\OneDrive\Pulpit\BDP\date.txt"
$date = Get-Content "C:\Users\anklo\OneDrive\Pulpit\BDP\date.txt"

Remove-Item -Path "C:\Users\anklo\OneDrive\Pulpit\BDP\date.txt"

$lines = $table_tmp.Count -3
$zip_file = "C:\Users\anklo\OneDrive\Pulpit\BDP\$NEWTABLE.zip"

$bod2 = "Creation date: $date
Number of lines in CSV file: $lines"

$Creds = (Get-Credential -Credential "$my_email")

Send-MailMessage -To $To -From $my_email -Subject $Sub -Body $bod2 -Attachments $zip_file -SmtpServer $SMTP -Credential $Creds -UseSsl -Port 587 -DeliveryNotificationOption never

$date = Get-Date 
$date, " : sending second e-mail : Successful!" >> $log
