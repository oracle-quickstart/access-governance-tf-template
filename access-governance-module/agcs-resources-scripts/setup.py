import subprocess
import sys


def install():
    subprocess.check_call([sys.executable, "-m", "pip3", "install -r", "requirements.txt", "--user"])


if __name__ == '__main__':
    install()
