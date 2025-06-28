#!/bin/bash
set -e
git fetch --tags
TAGS=( $(git tag -l "autobuild-*" | sort -r) )

KEEP_LATEST=14
KEEP_MONTHLY=24

LATEST_TAGS=()
MONTHLY_TAGS=()

CUR_MONTH="-1"

for TAG in ${TAGS[@]}; do
    if [[ ${#LATEST_TAGS[@]} -lt ${KEEP_LATEST} ]]; then
        LATEST_TAGS+=( "$TAG" )
    fi

    if [[ ${#MONTHLY_TAGS[@]} -lt ${KEEP_MONTHLY} ]]; then
        TAG_MONTH="$(echo $TAG | cut -d- -f3)"

        if [[ ${TAG_MONTH} != ${CUR_MONTH} ]]; then
            CUR_MONTH="${TAG_MONTH}"
            MONTHLY_TAGS+=( "$TAG" )
        fi
    fi
done

# Silinecek olanları çıkar
for TAG in "${LATEST_TAGS[@]}" "${MONTHLY_TAGS[@]}"; do
    TAGS=( "${TAGS[@]/$TAG}" )
done

# Kalan tag'lar üzerinden ilerle
for TAG in "${TAGS[@]}"; do
    echo "Checking $TAG..."

    if gh release view "$TAG" &>/dev/null; then
        echo "Deleting release and tag $TAG"
        gh release delete --cleanup-tag --yes "$TAG"
    else
        echo "No release found for $TAG, skipping delete"
        git tag -d "$TAG"  # Optional: sadece local tag'i silmek için
    fi
done

git push --tags --prune
