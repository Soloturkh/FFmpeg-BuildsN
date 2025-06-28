#!/bin/bash
set -euo pipefail

git fetch --tags

# Tüm autobuild tag'lerini topla (yeniye göre sırala)
TAGS=( $(git tag -l "autobuild-*" | sort -r) )

KEEP_LATEST=14
KEEP_MONTHLY=24

LATEST_TAGS=()
MONTHLY_TAGS=()
PRESERVE_TAGS=()

CUR_MONTH="-1"

for TAG in "${TAGS[@]}"; do
    # En yeni 14 tag'ı tut
    if [[ ${#LATEST_TAGS[@]} -lt $KEEP_LATEST ]]; then
        LATEST_TAGS+=( "$TAG" )
        PRESERVE_TAGS+=( "$TAG" )
    fi

    # Aylık 1'er tane, en fazla 24 ay tut
    if [[ ${#MONTHLY_TAGS[@]} -lt $KEEP_MONTHLY ]]; then
        TAG_DATE="$(echo "$TAG" | cut -d- -f2-4)"  # YYYY-MM-DD
        TAG_MONTH="${TAG_DATE:0:7}"               # YYYY-MM

        if [[ "$TAG_MONTH" != "$CUR_MONTH" ]]; then
            CUR_MONTH="$TAG_MONTH"
            MONTHLY_TAGS+=( "$TAG" )
            PRESERVE_TAGS+=( "$TAG" )
        fi
    fi
done

# PRESERVE_TAGS dizisinde olmayanları sil
for TAG in "${TAGS[@]}"; do
    if printf '%s\n' "${PRESERVE_TAGS[@]}" | grep -qx "$TAG"; then
        echo "Keeping $TAG"
    else
        echo "Checking $TAG..."

        if gh release view "$TAG" &>/dev/null; then
            echo "Deleting release and tag $TAG"
            gh release delete --cleanup-tag --yes "$TAG"
        else
            echo "No release found for $TAG, deleting tag only"
            git tag -d "$TAG" || true
            git push origin ":refs/tags/$TAG" || true
        fi
    fi
done

# Son olarak kalan tag'leri sunucu ile senkronize et
git push --prune --tags
