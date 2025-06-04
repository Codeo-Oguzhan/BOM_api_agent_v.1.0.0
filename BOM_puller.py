import os
import time
import json
import requests
from datetime import datetime

def main():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    config_path = os.path.join(script_dir, "config.json")
    
    with open(config_path, "r") as file:
        config = json.load(file)

    api_base_url = config.get("api_url")
    target_folder = config.get("target_folder")
    interval_seconds = config.get("interval_seconds")

    while True:
        try:
            # Fetch unpulled data from API
            response = requests.get(f"{api_base_url}/unpulled")
            response.raise_for_status()
            data = response.json()

            if data:  # Only process if there's data
                # Ensure target folder exists
                save_path = os.path.join(target_folder)
                os.makedirs(save_path, exist_ok=True)

                for item in data:
                    # Create a copy of the item without the specified fields
                    filtered_item = {
                        'topLevelPartId': item['topLevelPartId'],
                        'genericPartPrefix': item['genericPartPrefix'],
                        'attributes': item['attributes'],
                        'bom': item['bom']
                    }
                    
                    output_file = os.path.join(save_path, f"{item['id']}.json")
                    with open(output_file, "w", encoding="utf-8") as out_file:
                        json.dump(filtered_item, out_file, ensure_ascii=False, indent=2)
                    
                    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    print(f"[INFO {current_time}] Data saved to {output_file}")

                    # Wait 2 seconds before saving the next file
                    time.sleep(2)

                # Mark each item as pulled
                for item in data:
                    try:
                        mark_response = requests.put(f"{api_base_url}/{item['id']}/pulled")
                        mark_response.raise_for_status()
                        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        print(f"[INFO {current_time}] Marked item {item['id']} as pulled")
                    except Exception as e:
                        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        print(f"[ERROR {current_time}] Failed to mark item {item['id']} as pulled: {e}")
                print(f"------------------------------")
            else:
                current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"[INFO {current_time}] No new data found in the last {interval_seconds} seconds")
                print(f"------------------------------")

        except Exception as e:
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"[ERROR {current_time}] {e}")

        time.sleep(interval_seconds)

if __name__ == "__main__":
    main()