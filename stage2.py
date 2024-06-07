import boto3
import requests
import os
import pandas as pd
from decimal import Decimal
import json
from landingai.predict import Predictor
from landingai.pipeline.frameset import Frame

AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')

S3_BUCKET_NAME = "bucket-to-keep-csv"
REGION= "us-west-2"

predictor = Predictor(
    endpoint_id=os.environ.get('endpoint_id'),
    api_key=os.environ.get('api_key'),
)



url = "https://cwwp2.dot.ca.gov/data/d1/cctv/cctvStatusD01.csv" #URL for the CSV file
path = "/home/ubuntu/" 

s3_uri_folder1="s3://bucket-to-keep-csv/raw_images/" # URI of the Folder in the S3 bucket 
s3_uri_folder2="s3://bucket-to-keep-csv/processed_images/" 

#spliting the URI to get the folder name from bucket

arr1=s3_uri_folder1.split('/')
bucket =arr1[2]
prefix1=""
for i in range(3,len(arr1)-1):
    prefix1=prefix1+arr1[i]+"/"

arr2=s3_uri_folder2.split('/')
bucket =arr2[2]
prefix2=""
for i in range(3,len(arr2)-1):
    prefix2=prefix2+arr2[i]+"/"



#AWS credential function
def aws_credential(resource, region=False):
    if region and resource == 'dynamodb':
        s3_client = boto3.resource(resource, aws_access_key_id=AWS_ACCESS_KEY_ID, aws_secret_access_key=AWS_SECRET_ACCESS_KEY, region_name=region)    
    else:
        s3_client = boto3.client(resource, aws_access_key_id=AWS_ACCESS_KEY_ID, aws_secret_access_key=AWS_SECRET_ACCESS_KEY)
    return s3_client

#AWS bucket function

def S3_path(file_name,S3_BUCKET_NAME,folder_name):
    aws_cred = aws_credential(resource='s3')
    aws_cred.upload_file(file_name, S3_BUCKET_NAME, f"{folder_name}/{file_name}") #path to upload the CSV file

#Download the image from URL and upload to S3
def download_and_upload(url, file_name, S3_BUCKET_NAME):
    try:

        with requests.Session() as session:
            response = session.get(url)
            content = response.content.decode()
        with open(f'{path}StatusD01.csv', 'w') as f:
            f.write(content)

        if response.status_code == 200:
            aws_credential(resource='s3')
            S3_path(file_name,S3_BUCKET_NAME,folder_name='original_csv')
            print(f"Downloaded {file_name} from {url} and uploaded to S3 bucket {S3_BUCKET_NAME}")
            return response
        else:
            print(f"Error downloading {file_name}: {response.status_code}")
    except Exception as e:
        raise Exception(f"Error downloading and uploading {file_name}: {e}")
    

# Uploading the Images to S3 Bucket from the URLs in CSV


def change_image_name_and_upload():
   
    data_frame = pd.read_csv(f'{path}StatusD01.csv',) 
    aws_credential(resource='s3')
    for data in data_frame.iterrows():
        data = data[1]
        img_name = f"Img-{data['recordDate']}-{data['recordTime']}-{data['recordEpoch']}-{data['district']}.jpg"
        response = requests.get(data['currentImageURL'], stream=True)
        
        aws_credential(resource='s3').upload_fileobj(response.raw, 'bucket-to-keep-csv', f"raw_images/{img_name}")
    
    print('image upload completed')

#Adding colums to csv file
def list_s3_files_using_client(bucket, prefix1):
    s3_client=aws_credential(resource="s3")
    response1 = s3_client.list_objects_v2(Bucket=bucket,  Prefix=prefix1) # Featch Meta-data of all the files in the folder


    df = pd.read_csv(f"{path}StatusD01.csv")

    images1 = response1.get("Contents")
    
    url_list1 = []
    for image1 in images1[1:]: 
        file_path1=image1['Key']
        object_url="https://"+bucket+".s3.amazonaws.com/"+file_path1 #create Object URL  Manuall
        recordepoch = int(object_url.split("-")[-2])
        
        image_name= (object_url.split("/"))[-1]
        image = Frame.from_image(object_url) #adding S3 bucket path to Landing.ai 
        image.resize(width=512, height=512)

        image.run_predict(predictor=predictor) #
        response = image.overlay_predictions() 

        #conver the label_name form tuple to list
        labels = [response.predictions[index].label_name for index in range(len(response.predictions))]

            
        #save the predicted images locally
        image.save_image(f"{path}{image_name}",include_predictions=True)

        #upload predicted images to s3
        aws_credential(resource='s3').upload_file(f"{path}{image_name}",bucket,f"processed_images/{image_name}")
        os.remove(f"{path}{image_name}")

        
    
   
    # storing the rawimageurl and responses from landing.ai in CSV file

    for row in df.iterrows():
        row = dict(row[1])
        if recordepoch == row["recordEpoch"]:
            row['rawimageURL'] = object_url    
            row['Pothole'] = "false"
            row['Construction'] = "false"
            row['Debris'] = "false"
            row['FlashFlood'] = "false"
            row['Fog'] = "false"
            row['RoadKill'] = "false"
            row['Car'] = "false"
            row['Bus'] = "false"
            row['Tractor_Trailer'] = "false"

            for label in labels:
                row[label] = "true"


            url_list1.append(row)
            
    
    

    #creating new modified file
    df = pd.DataFrame(url_list1)
    df.to_csv('StatusD01-.csv', index=False)
    print("CSV file modification done")

#adding the processed imageurl to CSV file
def add_processed_imgae_url(bucket, prefix2):
    s3_client=aws_credential(resource="s3")
    response2 = s3_client.list_objects_v2(Bucket=bucket,Prefix=prefix2) # Featch Meta-data of all the files in the folder
    df = pd.read_csv(f"{path}StatusD01-.csv")
    images2 = response2.get("Contents")
    response_dict2={}

    url_list2 = []
    for image2 in images2[1:]: 
        file_path2=image2['Key']
        processed_url="https://"+bucket+".s3.amazonaws.com/"+file_path2 #create Object URL  Manuall
        record_epoch = int(processed_url.split("-")[-2])

        response_dict2[record_epoch]={"processed_url":processed_url}

        for row in df.iterrows():
            row = dict(row[1])
        
            if record_epoch == row['recordEpoch']:
                row['PredictedImageURL'] =processed_url 

                url_list2.append(row)
                break
                

    df = pd.DataFrame(url_list2)
    df.to_csv('StatusD01-modified.csv', index=False)
    print("processed image url added in the CSV")

#Uploading the Modified CSV file to S3 BUCKET 

def upload_new_csv(S3_BUCKET_NAME , file_name):
    aws_credential(resource='s3')
    S3_path(file_name, S3_BUCKET_NAME,folder_name='modified_csv')
    print("csv file upload done") 
    

#function for inserting the data to dynamodb
    
def insert_dynamo_item(tablename,item_lst):
    dynamoTable = dynamodb.Table(tablename)
    
    for record in item_lst:
        item = json.loads(json.dumps(record), parse_float=Decimal)
        dynamoTable.put_item(Item=item)
    print("data uploaded to dynamodb")


# Remove the file from Local  
        
def delete_files():
    os.remove (f'{path}StatusD01.csv')
    os.remove (f'{path}StatusD01-.csv')
    os.remove (f'{path}StatusD01-modified.csv')
    print('CSV file deleted from local')

 
if __name__ == "__main__":

    
    download_and_upload(url, "StatusD01.csv", S3_BUCKET_NAME)
    change_image_name_and_upload()
    list_s3_files_using_client(bucket=bucket, prefix1= prefix1)
    add_processed_imgae_url(bucket=bucket, prefix2=prefix2)
    upload_new_csv(S3_BUCKET_NAME="bucket-to-keep-csv",file_name='StatusD01-modified.csv')

    #converting the CSV file to json format
    data_dict = json.loads(pd.read_csv(f'{path}StatusD01-modified.csv').to_json(orient='records'))

    #Creating a list of Dictionaries and their table name.
    lst_Dicts = [{'item': data_dict, 'table':'Landing.ai'}]

    #Connect to DynamoDb Function
    dynamodb = aws_credential('dynamodb', region=REGION)
    # dynamodb = boto3.resource('dynamodb', aws_access_key_id=AWS_ACCESS_KEY_ID, aws_secret_access_key=AWS_SECRET_ACCESS_KEY, region_name=REGION)

    #Upload Content to DynamoDB
    
    insert_dynamo_item(tablename='Landing.ai', item_lst=data_dict)

    delete_files()    
