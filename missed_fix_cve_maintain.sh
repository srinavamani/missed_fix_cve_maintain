#!/bin/bash

sqlite3 $PWD/sample.db <<'END_SQL'
create table if not exists data(CVE_ID varchar(10), Package_Name varchar(10), Version varchar(10), Affected_version varchar(5000), Curation_notes varchar(5000), OS varchar(50), Status varchar(10));
END_SQL

mkdir -p $PWD/rough
rm -rf $PWD/rough/*

cve_details_entry()
{
			read -p "Package Name - " Package_name
			if [ $Package_name ]; then
			read -p "Version - " Version
			if [ $Version ]; then
			Status=1 # Need to review 
			echo "Affected Versions : "
			read -d '!' Affected_versions
			echo -e "\n\n"
			echo "Curation Notes : "
			read -d '!' Curation
			echo -e "\n\n"
			read -p "OS - " OS
			if [ $OS ]; then
			clear
			echo -e "Verify all the details are correct\n"
			echo "--------------------------------------------------------------------"
			echo "$CVE_ID"
			echo "---------------------"
			echo "$Package_name"
			echo "---------------------"
			echo "$Version"
			echo "---------------------"
			echo "$Affected_versions"
			echo "---------------------"
			echo "$Curation"
			echo "---------------------"
			echo "$OS"
			echo "---------------------"
			echo "$Status"
			echo "---------------------"
			Added_by=`git config --list | grep email | cut -d '=' -f2`
			echo "Added by - $Added_by"
			echo -e "--------------------------------------------------------------------\n\n"
			fi
			fi
			fi
}

save_update_details()
{
				echo "Saving..."
				sleep 1
				echo "Successfully saved into database"
				sleep 2
				clear
				if [ $1 = "s" ]
				then
					echo "insert into data values ('$CVE_ID', '$Package_name', '$Version', '$Affected_versions', '$Curation', '$OS', '$Status');" | sqlite3 $PWD/sample.db
				elif [ $1 = "u" ]
				then
					echo "UPDATE data SET Package_Name='$Package_name', Version='$Version', Affected_version='$Affected_versions', Curation_notes='$Curation', OS='$OS', Status='$Status' WHERE CVE_ID='$2'" | sqlite3 $PWD/sample.db
				fi
}

echo -e "\n*****Welcome to missed fix CVE task*****\n"
read -p "Cross-Verification(c) OR New Entry(n) : " Entry_level

if [ $Entry_level ]
then
	if [ $Entry_level = "n" ]
	then
		while [ 1 ]
		do
			clear
			echo "New entry details required..."
			read -p "CVE ID - " CVE_ID
			if [ $CVE_ID ]
			then
				echo "SELECT CVE_ID FROM data;" | sqlite3 $PWD/sample.db > $PWD/rough/already_exist.txt
				if cat $PWD/rough/already_exist.txt | grep -q "$CVE_ID"; then
					echo -e "$CVE_ID - Already Exist\n\n"
					sleep 3
					
					read -p "Do you want to edit (y/n) : " edit_flag
					echo -e "\nEditing $CVE_ID details\n"

					if [ $edit_flag = "y" ]
					then
						cve_details_entry
						save_update_details 'u' $CVE_ID
					fi
				else
					cve_details_entry
					save_update_details 's' $CVE_ID
				fi
		else
		echo ""
		read -p "Do you want to exit (y/n) : " Exit 
		if [ $Exit = "y" ]
		then
			break
		fi
		fi
		done

	elif [ $Entry_level = "c" ]
	then
		echo ""
		read -p "Verification(v) OR Approval(a) : " process

		if [ $process = "v" ]
		then
			echo -e "\nVerification process\n\nListing all the CVE ID's need's verification"
			echo "SELECT CVE_ID, Status FROM data;" | sqlite3 $PWD/sample.db > $PWD/rough/verify_total_list.txt

			while IFS= read -r line; do
				if [ $line ]; then
					verify_status=`echo "${line: -1}"`
					if [ $verify_status = "1" ]; then
						echo "$line" | rev | cut -c 3- | rev >> $PWD/rough/Review_list.txt
					fi
				fi
			done < $PWD/rough/verify_total_list.txt
			clear
			echo -e "\nFollowing CVE's need to verify,\n"
			cat $PWD/rough/Review_list.txt
			sleep 1
			while [ 1 ]
			do
#				clear
				echo -e "\n\nTo view the details of particular CVE,"
				read -p "CVE_ID - " CVE
				if [ $CVE ]
				then
					if cat $PWD/rough/Review_list.txt | grep -q "$CVE"; then
						clear
						echo -e "\nCVE Details:\n"
						echo "SELECT CVE_ID FROM data WHERE CVE_ID = '$CVE';" | sqlite3 $PWD/sample.db
						echo -e "------------------------------------------------------------"
						echo "SELECT Package_Name FROM data WHERE CVE_ID = '$CVE';" | sqlite3 $PWD/sample.db
						echo -e "------------------------------------------------------------"
						echo "SELECT Version FROM data WHERE CVE_ID = '$CVE';" | sqlite3 $PWD/sample.db
						echo -e "------------------------------------------------------------"
						echo "SELECT OS FROM data WHERE CVE_ID = '$CVE';" | sqlite3 $PWD/sample.db
						echo -e "------------------------------------------------------------"
						echo "SELECT Affected_version FROM data WHERE CVE_ID = '$CVE';" | sqlite3 $PWD/sample.db
						echo -e "------------------------------------------------------------"
						echo "SELECT Curation_notes FROM data WHERE CVE_ID = '$CVE';" | sqlite3 $PWD/sample.db
						echo -e "------------------------------------------------------------"

						read -p "If you want to update/edit any details(y/n) : " Status
						if [ $Status = "y" ]
						then
							echo "Need to edit the details - Feature will be added shortly"
						fi
						echo "Wait for 5 Sec"
						sleep 5
					else
						echo -e "\n\nNo such CVE ID in verification list.\nPlease try again..."
						sleep 3
					fi
				else
	        		        echo ""
			                read -p "Do you want to exit (y/n) : " Exit
                			if [ $Exit = "y" ]
		                	then
        		               		break
                			fi
				fi
			clear
		done
		elif [ $process = "a" ]
		then
			echo -e "\nApproval process"
		fi
	fi
else
	echo "Thank you..."
fi
