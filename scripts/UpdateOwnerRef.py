import os
import re
import argparse
import subprocess
import yaml


class UpdateOwnerRef:
    def __init__(self):
        self.mode = None
        self.file_names = []
        self.release_name = ''
        self.release_namespace = ''
        self.owner_ref = ''
        self.read_arguments()

    def read_arguments(self):
        parser = argparse.ArgumentParser(description='update owner ref for helm chart')
        parser.add_argument('-release_name', help='Helm chart release name ', required=True)
        parser.add_argument('-release_namespace', help='namespace in which helm chart exist ', required=True)
        parser.add_argument('-owner_ref', help='owner ref to add to the helm charts ', required=True)
        args = parser.parse_args()
        self.release_name = args.release_name
        self.release_namespace = args.release_namespace
        self.owner_ref = args.owner_ref

    @staticmethod
    def check_is_helm_installed():
        check_command = 'helm version --short --client'
        status, response = UpdateOwnerRef.run_command(check_command)
        if status != 0:
            print("Cannot connect to Helm. Make sure helm is installed on the machine.")
            return False
        lines = response.strip(os.linesep).split(os.linesep)
        for line in lines:
            line = line.lower()
            if not line.startswith("warning"):
                match = re.search("v\\d+.\\d+.\\d+", line)
                if match is None or len(match.string) <= 0:
                    print("Could not parse helm version from version string: {0}".format(line))
                    return False
                version_num_breakdown = line.split(".")
                if version_num_breakdown[0] != "v3":
                    print(
                        "helm version 3.0.0 or greater is required. Your version: {0} is not supported currently".format(
                            line))
                    return False
        return True

    def run(self):
        list_command = 'helm get manifest ' + self.release_name + ' -n ' + self.release_namespace
        if UpdateOwnerRef.check_is_helm_installed():
            status, response = UpdateOwnerRef.run_command(list_command)
            if status != 0:
                print("Cannot find release to update.")
            resources = response.split("---")
            for resource in resources:
                yaml_dict = yaml.safe_load(resource)
                if yaml_dict and 'kind' in yaml_dict:
                    update_command = 'kubectl patch ' + yaml_dict['kind'] + ' ' + yaml_dict['metadata'][
                        'name'] + ' -n ' + self.release_namespace + ' -p \'{"metadata": {"ownerReferences": '+self.owner_ref+' }}\''
                    status, response = UpdateOwnerRef.run_command(update_command)
                    if status != 0:
                        print("Error updating " + yaml_dict['kind'] + " " + yaml_dict['metadata']['name'])
                        print(response)
                        print("update command: " + update_command)
                    else:
                        print("Successfully updated: " + yaml_dict['kind'] + " " + yaml_dict['metadata']['name'])
        else:
            exit(0)

    @staticmethod
    def run_command(command):
        process = subprocess.Popen('%s 2>&1' % command, shell=True, stdout=subprocess.PIPE)
        response = process.stdout.read()
        status = process.wait()
        if not isinstance(response, str) and isinstance(response, (bytes, bytearray)):
            response = response.decode("UTF-8")
        return status, response


if __name__ == '__main__':
    try:
        updateOwnerRef = UpdateOwnerRef()
        updateOwnerRef.run()

    except Exception as e:
        print(e)
