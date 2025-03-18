import boto3
from datetime import datetime, timezone

def get_lowest_spot_price():
    client = boto3.client('ec2', region_name='eu-central-1')
    response = client.describe_spot_price_history(
        InstanceTypes=['m4.large'],
        ProductDescriptions=['Linux/UNIX'],
        StartTime=datetime.now(timezone.utc).isoformat(),
        MaxResults=10
    )
    for item in response['SpotPriceHistory']:
        print(item)
    lowest_price_entry = min(response['SpotPriceHistory'], key=lambda x: float(x['SpotPrice']))
    return lowest_price_entry


def prompt_user(lowest_price, az):
    print(f"Lowest Spot Price: {lowest_price} in AZ: {az}")
    user_input = input("Do you want to update 'variables.tf' with this lowest spot price and AZ? (Yes/No): ").strip().lower()
    return user_input in ["yes", "y"]

def update_variables_tf(file_path, spot_price, az):
    updated_lines = []
    found_spot_price = False
    found_az = False

    with open(file_path, 'r') as file:
        for line in file:
            if 'variable "spot_price"' in line:
                updated_lines.append(line)
                found_spot_price = True
            elif 'default     =' in line and found_spot_price:
                updated_lines.append(f'  default     = "{spot_price}"  # Updated to lowest spot price\n')
                found_spot_price = False
            elif 'variable "availability_zone"' in line:
                updated_lines.append(line)
                found_az = True
            elif 'default     =' in line and found_az:
                updated_lines.append(f'  default     = "{az}"  # Updated to lowest AZ\n')
                found_az = False
            else:
                updated_lines.append(line)

    with open(file_path, 'w') as file:
        file.writelines(updated_lines)

def main():
    lowest_price_entry = get_lowest_spot_price()
    lowest_price = lowest_price_entry['SpotPrice']
    az = lowest_price_entry['AvailabilityZone']

    if prompt_user(lowest_price, az):
        update_variables_tf('variables.tf', lowest_price, az)
        print(f"'variables.tf' has been updated with Spot Price: {lowest_price} and AZ: {az}")
    else:
        print("No changes made to 'variables.tf'.")

if __name__ == "__main__":
    main()
