import json
import os
import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda function to load sample movie data into OpenSearch
    """
    endpoint = os.environ['OPENSEARCH_ENDPOINT']
    bucket = os.environ['S3_BUCKET']
    key = os.environ['S3_KEY']
    master_user = os.environ['MASTER_USER']
    master_password = os.environ['MASTER_PASSWORD']
    
    print(f"Connecting to OpenSearch: {endpoint}")
    print(f"Loading data from: s3://{bucket}/{key}")
    
    try:
        # Create OpenSearch client with basic auth
        client = OpenSearch(
            hosts=[{'host': endpoint, 'port': 443}],
            http_auth=(master_user, master_password),
            use_ssl=True,
            verify_certs=True,
            connection_class=RequestsHttpConnection,
            timeout=30
        )
        
        # Test connection
        info = client.info()
        print(f"Connected to OpenSearch cluster: {info['cluster_name']}")
        print(f"OpenSearch version: {info['version']['number']}")
        
        # Create index with mappings
        index_name = 'movies'
        index_body = {
            'settings': {
                'index': {
                    'number_of_shards': 1,
                    'number_of_replicas': 1 if info.get('cluster_nodes', 1) > 1 else 0
                }
            },
            'mappings': {
                'properties': {
                    'title': {
                        'type': 'text',
                        'fields': {
                            'keyword': {
                                'type': 'keyword'
                            }
                        }
                    },
                    'year': {'type': 'integer'},
                    'genre': {'type': 'keyword'},
                    'director': {
                        'type': 'text',
                        'fields': {
                            'keyword': {
                                'type': 'keyword'
                            }
                        }
                    },
                    'rating': {'type': 'float'},
                    'description': {'type': 'text'}
                }
            }
        }
        
        # Delete index if it exists (for redeployment)
        if client.indices.exists(index=index_name):
            client.indices.delete(index=index_name)
            print(f"Deleted existing index: {index_name}")
        
        # Create the index
        client.indices.create(index=index_name, body=index_body)
        print(f"Created index: {index_name}")
        
        # Load data from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        movies = json.loads(response['Body'].read())
        print(f"Loaded {len(movies)} movies from S3")
        
        # Bulk index movies
        success_count = 0
        error_count = 0
        
        for i, movie in enumerate(movies):
            try:
                response = client.index(
                    index=index_name,
                    id=i + 1,
                    body=movie,
                    refresh=True
                )
                success_count += 1
                print(f"Indexed movie {i+1}: {movie['title']}")
            except Exception as e:
                error_count += 1
                print(f"Error indexing movie {movie.get('title', 'Unknown')}: {str(e)}")
        
        # Refresh the index
        client.indices.refresh(index=index_name)
        
        # Get index stats
        stats = client.indices.stats(index=index_name)
        doc_count = stats['_all']['primaries']['docs']['count']
        
        result = {
            'statusCode': 200,
            'body': {
                'message': f'Successfully loaded movies into OpenSearch',
                'index': index_name,
                'documents_loaded': success_count,
                'errors': error_count,
                'total_documents': doc_count,
                'endpoint': f'https://{endpoint}',
                'dashboards': f'https://{endpoint}/_dashboards',
                'cluster_name': info['cluster_name'],
                'version': info['version']['number']
            }
        }
        
        print(json.dumps(result['body'], indent=2))
        return result
        
    except Exception as e:
        error_message = f"Error loading data into OpenSearch: {str(e)}"
        print(error_message)
        return {
            'statusCode': 500,
            'body': {
                'error': error_message
            }
        }
