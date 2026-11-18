export KAS_CONTAINER_IMAGE_DISTRO=debian-bookworm

python -c "import yaml; yaml.safe_load(open('pine64-plus.yml')); print('valid')"
kas-container build pine64-plus.yml
