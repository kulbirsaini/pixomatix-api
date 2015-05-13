aws_config = Rails.application.config_for(:aws)

Aws.config.update(
  region: aws_config['region'],
  credentials: Aws::Credentials.new(aws_config['access_key_id'], aws_config['secret_access_key'])
)
Rails.application.config.x.s3_bucket = aws_config['s3_bucket']
