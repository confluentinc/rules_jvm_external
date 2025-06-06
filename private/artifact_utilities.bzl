#
# Utilites for working with artifacts
#

load("//:specs.bzl", "utils")

# TODO VR: Why isn't all this processing just done in the LockFileConverter?
def deduplicate_and_sort_artifacts(dep_tree, artifacts, excluded_artifacts, verbose):
    # The deps json returned from coursier can have duplicate artifacts with
    # different dependencies and exclusions. We want to de-duplicate the
    # artifacts and chose the ones that most closely match the exclusions
    # specified in the maven_install declaration and not chose ones with
    # empty dependencies if possible

    # First we find all of the artifacts that have exclusions
    artifacts_with_exclusions = {}
    for a in artifacts:
        coordinate = utils.artifact_coordinate(a)
        if "exclusions" in a and len(a["exclusions"]) > 0:
            deduped_exclusions = {}
            for e in excluded_artifacts:
                deduped_exclusions["{}:{}".format(e["group"], e["artifact"])] = True
            for e in a["exclusions"]:
                if e["group"] == "*" and e["artifact"] == "*":
                    deduped_exclusions = {"*:*": True}
                    break
                deduped_exclusions["{}:{}".format(e["group"], e["artifact"])] = True
            parts = coordinate.split(":")
            coordinate = "{}:{}".format(parts[0], parts[1])
            artifacts_with_exclusions[coordinate] = deduped_exclusions.keys()

        # As we de-duplicate the list keep the duplicate artifacts with exclusions separate
        # so we can look at them and select the one that has the same exclusions
        # Also prefer the duplicates with non-empty dependency lists
        duplicate_artifacts_with_exclusions = {}
        deduped_artifacts = {}
        null_artifacts = []
        for artifact in dep_tree["dependencies"]:
            # Coursier expands the exclusions on an artifact to all of its dependencies.
            # This is too broad, so we set them to empty and append the exclusion map
            # to the dep_tree using the user-defined exclusions.
            artifact["exclusions"] = []
            if artifact["file"] == None:
                null_artifacts.append(artifact)
                continue
            if artifact["coord"] in artifacts_with_exclusions:
                if artifact["coord"] in duplicate_artifacts_with_exclusions:
                    duplicate_artifacts_with_exclusions[artifact["coord"]].append(artifact)
                else:
                    duplicate_artifacts_with_exclusions[artifact["coord"]] = [artifact]
            elif artifact["file"] in deduped_artifacts:
                if len(artifact["dependencies"]) > 0 and len(deduped_artifacts[artifact["file"]]["dependencies"]) == 0:
                    deduped_artifacts[artifact["file"]] = artifact
            else:
                deduped_artifacts[artifact["file"]] = artifact

        sorted_deduped_values = []
        for key in sorted(deduped_artifacts.keys()):
            sorted_deduped_values.append(deduped_artifacts[key])

    dep_tree.update({"dependencies": sorted_deduped_values + null_artifacts})
    dep_tree.update({"exclusions": artifacts_with_exclusions})

    return dep_tree
