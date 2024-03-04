import os
import oci
import requests
from requests.auth import HTTPBasicAuth


def get_si_signer_and_config():
    config = get_admin_config()
    t_key_content = config.get("key_content")
    t_key_file = config.get("key_file")
    if not config or not (t_key_content or t_key_file):
        config = {}
        signer = oci.auth.signers.InstancePrincipalsDelegationTokenSigner(delegation_token=os.environ["OCI_obo_token"])
    else:
        signer = oci.Signer.from_config(config)
    return signer, config


def get_admin_config():
    admin_pvt_key_path = os.environ["ADMIN_PRIVATE_KEY_PATH"]
    config = None
    if admin_pvt_key_path and not admin_pvt_key_path.isspace():
        config = {"log_requests": False, "additional_user_agent": "", "pass_phrase": None,
                  'user': os.environ["ADMIN_OCID_SERVICE_INSTANCE"],
                  'tenancy': os.environ["ADMIN_TENANCY_OCID_SERVICE_INSTANCE"],
                  'key_file': admin_pvt_key_path,
                  'region': os.environ["ADMIN_REGION_SERVICE_INSTANCE"],
                  "fingerprint": os.environ["ADMIN_FINGERPRINT_SERVICE_INSTANCE"],
                  "service_endpoint": "https://access-governance." + os.environ["ADMIN_REGION_SERVICE_INSTANCE"]
                                      + ".oci.oraclecloud.com"
                  }
    elif config is None:
        private_key_file = os.environ.get("TF_VAR_api_private_key_path")
        private_key = os.environ.get("TF_VAR_api_private_key")
        tenancy = os.environ.get("TF_VAR_tenancy_ocid")
        user = os.environ.get("TF_VAR_current_user_ocid")
        fingerprint = os.environ.get("TF_VAR_api_fingerprint")
        region = os.environ.get("TF_VAR_region")
        config = {
            "log_requests": False,
            "additional_user_agent": "",
            "pass_phrase": None,
            "user": user,
            "fingerprint": fingerprint,
            "tenancy": tenancy,
            "region": region,
            "service_endpoint": "https://access-governance." + region + ".oci.oraclecloud.com"
        }
        if private_key_file is not None and not private_key_file.isspace():
            config["key_file"] = private_key_file
        elif private_key is not None and not private_key.isspace():
            config["key_content"] = private_key

    return config


def get_auth_url():
    return os.environ["IDCS_ENDPOINT"] + "/oauth2/v1/token"


def get_idcs_access_token(signer):
    token_url = get_auth_url()
    headers = {'Content-type': 'application/x-www-form-urlencoded'}
    body = {
        "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
        "scope": "urn:opc:idm:__myscopes__",
        "requested_token_type": "urn:ietf:params:oauth:token-type:access_token"
    }
    response = requests.post(token_url, auth=signer, headers=headers, data=body)
    response_json = response.json()
    return response_json['access_token']


def get_ag_authorization_token(user, password, ag_instance_url):
    token_url = get_auth_url()
    headers = {'Content-type': 'application/x-www-form-urlencoded'}
    body = {
        "grant_type": "client_credentials",
        "scope": ag_instance_url
    }
    response = requests.post(token_url, auth=HTTPBasicAuth(user, password), headers=headers, data=body)
    response_json = response.json()

    return response_json['access_token']


def get_agcs_user_pvt_keys():
    use_existing_user = os.environ["USE_EXISTING_AGCS_USER"]
    private_key = os.environ["AGCS_USER_PRIVATE_KEY"]
    agcs_user_pvt_key_path = os.environ["AGCS_USER_PRIVATE_KEY_PATH"]
    if use_existing_user.lower() == "true":
        if agcs_user_pvt_key_path and not agcs_user_pvt_key_path.isspace():
            agcs_user_pvt_key_file = open(agcs_user_pvt_key_path, "r")
            content_cs = agcs_user_pvt_key_file.read()
            agcs_user_pvt_key_file.close()
        else:
            content_cs = private_key
    else:
        content_cs = private_key

    return content_cs


def should_verify_ssl():
    return not is_namespace_used()


def is_namespace_used():
    namespace_url = os.environ["NAMESPACE_SERVICE_ENDPOINT"]
    if namespace_url and not namespace_url.isspace():
        return True
    return False


