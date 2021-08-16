#!/bin/bash
# Requires: awscli (http://aws.amazon.com/cli/)
# Prints out a list of all security groups and their settings, just for quickly auditing it.
#./
#[default]
#creds=`sed -e 's/^aws_/export\ aws_/' /home/.aws/credentials | grep aws_` 
#creds=`cat ~/.aws/credentials`
#accounts=`cat /home/.aws/accounts`
IFS=$'\n'
#for acred in $creds; do echo $acred | grep "["; done
# Your AWS credentials
#for p in $accounts; do
# Want to do this for all regions...
#p="default"

REGIONS=(`aws ec2 describe-regions --region eu-west-1 --output text | grep "-" | awk '{print $3}'`)
for REGION in ${REGIONS[*]}; do
    echo "=> $REGION"

    # Grab all the security group info for this region in one call.
    GFILE='/tmp/aws-sec-groups_$p'
    aws ec2 describe-security-groups --region $REGION --output text > $GFILE

    # Grab list of actively used security groups for EC2.
    EC2FILE='/tmp/aws-sec-groups-ec2_p'
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text --region $REGION | tr '\t' '\n' | sort | uniq > $EC2FILE

    # Grab list of actively used security groups for RDS.
    RDSFILE='/tmp/aws-sec-groups-rds_p'
    aws rds describe-db-security-groups --query 'DBSecurityGroups[*].EC2SecurityGroups[*].EC2SecurityGroupId' --output text --region $REGION | tr '\t' '\n' | sort | uniq > $RDSFILE

    # Loop over each line of the file and parse it.
    old_IFS=$IFS; IFS=$'\n'
    cat $GFILE | while read line
    do
        case $line in
            # Header
            SECURITYGROUPS*)
                PORT_HAS_GLOBAL_RULE=0
                SID=(`echo $line | awk '{print $3}'`)
                GNAME=(`echo $line | awk '{print $4}'`)

                # Determine if this group is currently being used by an EC2/RDS instance.
                EXTRA=""
                grep $SID $EC2FILE &> /dev/null
                if [ $? -ne 0 ]; then
                    grep $SID $RDSFILE &> /dev/null
                    if [ $? -ne 0 ]; then
                      EXTRA=" <= ** Not currently used by any EC2 or RDS instance in this region!"
                    fi
                fi

                echo "  => $SID ($GNAME) $EXTRA"
                ;;

            # Rule Info
            IPPERMISSIONS*)
                INPORT=(`echo $line | awk '{print $2}'`)
                OUTPORT=(`echo $line | awk '{print $4}'`)
                PROTO=(`echo $line | awk '{print $3}'`)
                ;;
            IPRANGES*)
                EXTRA=""
                CIDR=(`echo $line | awk '{print $2}'`)

                # If a global rule was already seen for this port combo, then this rule is redundant!
                if [[ "$PORT_HAS_GLOBAL_RULE" = "$PROTO:$INPORT-$OUTPORT" ]] ; then
                  EXTRA=" <= ** Redundant, /0 was already specified for $PORT_HAS_GLOBAL_RULE."
                fi

                # Check if we have the global rule enabled.
                if [[ "$CIDR" = "0.0.0.0/0" ]]; then
                    EXTRA=" (!!)" # Mark it as potentially dangerous.
                    PORT_HAS_GLOBAL_RULE="$PROTO:$INPORT-$OUTPORT" # Also keep track, as it makes other rules redundant.
                fi

                echo -e "    => $PROTO:$INPORT->$OUTPORT\t\t$CIDR $EXTRA"
                ;;
            USERIDGROUPPAIRS*)
                EXTRA=""
                GROUPID=(`echo $line | awk '{print $2}'`)
                GROUPNAME=(`echo $line | awk '{print $3}'`)

                # If a global rule was already seen for this port combo, then this rule is redundant!
                if [[ "$PORT_HAS_GLOBAL_RULE" = "$PROTO:$INPORT-$OUTPORT" ]] ; then
                  EXTRA=" <= ** Redundant, /0 was already specified for $PORT_HAS_GLOBAL_RULE."
                fi

                echo -e "    => $PROTO:$INPORT->$OUTPORT\t\t$GROUPID ($GROUPNAME) $EXTRA"
                ;;
        esac
    done
  done
    IFS=$old_IFS

    # Clean up
    #rm $GFILE
    #rm $EC2FILE
    #rm $RDSFILE
#done

# Remove any credentials from env.
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

echo ""