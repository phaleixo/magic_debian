from flask import Flask, render_template
import subprocess
import os

diretorio_base = os.path.abspath(os.path.dirname(__file__))
apps_remover = os.path.join(diretorio_base, 'apps_remover.sh')
tweak = os.path.join(diretorio_base, 'tweaks.sh')

app = Flask(__name__)

@app.route('/')
def index():
    distribution = subprocess.run(['lsb_release', '-cs'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    distribution = distribution.stdout.decode().strip()
    
    if distribution == "bookworm":
        return render_template('index.html')
    else:
        return render_template('error.html')

@app.route('/limpeza')
def limpeza():
    return render_template('limpeza.html')
    


@app.route('/tweaks')
def tweaks():
    subprocess.run([apps_remover], shell=True)
    return render_template('tweaks.html')
    
    

@app.route('/finish')
def finish():
    subprocess.run([tweak], shell=True) # Execute o script shell
    return render_template('finish.html')


@app.route('/error')
def error_page():
    return render_template('error.html')

if __name__ == '__main__':
    app.run(debug=False)