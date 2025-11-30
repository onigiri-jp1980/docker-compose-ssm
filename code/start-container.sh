#!/bin/bash
set -e
set -u
set -o pipefail

usage() {
  cat 1>&2 <<EOF
Usage: $(basename $0) [オプション]
オプション:
  -p, --path=<パラメータのパス>        SSMパラメータストアのパスプレフィックス (default: /app/)
  -l, --profile=<プロファイル名>  使用するAWSプロファイル (default: default)
  -r, --region=<リージョン名>    使用するAWSリージョン (default: ap-northeast-1)
  -d, --dryrun               ドライランを実行/環境変数を表示
  -h, --help               ヘルプを表示して終了
EOF
  exit -1
}

show_params() {
  cat <<EOF
got params:
$params
EOF
}

region=${AWS_DEFAULT_REGION:-ap-northeast-1}
profile=${AWS_PROFILE:-default}
path=${BP_PATH:-/app/}
dryrun=false
# 長いオプションを処理
while [[ $# -gt 0 ]]; do
    case $1 in
        --region=*)
            region="${1#*=}"
            shift
            ;;
        -r | --region)
            region="$2"
            shift 2
            ;;
        --path=*)
            path="${1#*=}"
            shift
            ;;
        -p | --path)
            path="$2"
            shift 2
            ;;
        --profile=*)
            profile="${1#*=}"
            shift
            ;;
        -l | --profile)
            profile="$2"
            shift 2
            ;;
        -d | --dryrun)
            dryrun=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done
params=$(aws ssm get-parameters-by-path   --path "$path"\
   --recursive   --with-decryption  \
    --output json \
    --region $region \
    | jq -r '.Parameters[] | "\(.Name | split("/")[-1])=\(.Value)"')
for param in $params; do
    export $param
done
if [ "$dryrun" = true ]; then
    show_params
else
    docker compose run --rm app env
fi