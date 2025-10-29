#!/bin/bash

# Herramientas utilizadas: sherlock, aliasrecon, eyewitness, zehef, exiftool, whocalld, ipwho.is
# Permite verificar usuarios, dominios, correos, imágenes, teléfonos e IPs

# Función para mostrar animación de carga
site=$(pwd)
spinner() {
    local duration=$1
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    for i in $(seq 1 $duration); do
        printf "\r%s" "${frames[i % ${#frames[@]}]}"
        sleep 0.1
    done
    printf "\r"
}

# Pedir al usuario el tipo de dato
read -p "¿Qué deseas analizar? (usuario/dominio/correo/imagen/telefono/ip): " tipo

# Empezar 
case "$tipo" in

    usuario)
        read -p "Introduce el nombre de usuario: " valor
        read -p "¿Qué quieres usar, sherlock o aliasrecon (s/a)? " res1

        if [[ "$res1" =~ ^[sS] ]]; then
            echo "Analizando el usuario '$valor' con sherlock..."
            spinner 20

            if sherlock --version >/dev/null 2>&1; then
                echo "Analizando usuario..."
                sherlock "$valor" -o resultado_sherlock
                echo "Resultados guardados en resultado_sherlock"
            else
                echo "Sherlock no está instalado."
                read -p "¿Quieres instalarlo ahora? (s/n): " respuesta
                if [[ "$respuesta" =~ ^[Ss]$ ]]; then
                    echo "Instalando Sherlock..."
                    sudo apt update
                    sudo apt install sherlock -y
                    spinner 15
                    if sherlock --version >/dev/null 2>&1; then
                        echo "Sherlock se instaló correctamente."
                    	echo "Analizando usuario..."
	                sherlock "$valor" -o resultado_sherlock
        	        echo "Resultados guardados en resultado_sherlock"
		    else
                        echo "No se pudo instalar Sherlock."
                        exit 1
                    fi
                else
                    echo "No se instalará Sherlock, abortando análisis."
                    exit 1
                fi
            fi

        else
            echo "Analizando el usuario '$valor' con aliasrecon..."
            spinner 20

            if [ -d "$site/aliasrecon" ]; then
                cd "$site/aliasrecon" || exit 1
                nohup python3 app.py >/dev/null 2>&1 &
                echo $! > flask.pid

                # Esperar que el servidor Flask esté listo
                for i in {1..15}; do
                    if nc -z 127.0.0.1 5000 >/dev/null 2>&1; then
                        break
                    fi
                    spinner 5
                done

                curl -v -X POST -H "Content-Type: application/json" \
                    -d "{\"username\":\"$valor\"}" \
                    http://127.0.0.1:5000/search > ../resultado_"$valor"
                echo "Guardado en resultado_$valor"

                kill "$(cat flask.pid)"
                rm flask.pid
            else
                echo "aliasrecon no está instalado"
                read -p "¿Quieres instalar aliasrecon? (s/n): " respuesta
                if [[ "$respuesta" =~ ^[sS] ]]; then
                    echo "Instalando aliasrecon..."
                    sudo apt update
                    sudo apt install python3 python3-pip git -y
                    git clone https://github.com/unnohwn/aliasrecon.git
                    cd aliasrecon || exit 1
                    spinner 15
		    cd "$site/aliasrecon" || exit 1
               	    nohup python3 app.py >/dev/null 2>&1 &
               	    echo $! > flask.pid

                # Esperar que el servidor Flask esté listo
                    for i in {1..15}; do
                    	if nc -z 127.0.0.1 5000 >/dev/null 2>&1; then
                        	break
                    	fi
                    	spinner 5
                    done

                curl -v -X POST -H "Content-Type: application/json" \
                    -d "{\"username\":\"$valor\"}" \
                    http://127.0.0.1:5000/search > ../resultado_"$valor"
                echo "Guardado en resultado_$valor"

                kill "$(cat flask.pid)"
                rm flask.pid

                else
                    echo "No se instalará aliasrecon"
                    exit 1
                fi
            fi
        fi
        ;;

    dominio)
        read -p "Introduce el dominio (ejemplo.com): " valor
        echo "Analizando el dominio '$valor'..."
        spinner 15

        eyewitness --web --single "https://$valor" --threads 10 --delay 0 --timeout 60

        if eyewitness --help >/dev/null 2>&1; then
            echo "Análisis elaborado"
        else
            echo "Eyewitness no está instalado"
            read -p "¿Quieres instalarlo ahora? (s/n): " respuesta
            if [[ "$respuesta" =~ ^[Ss]$ ]]; then
                echo "Instalando Eyewitness..."
                sudo apt update
                sudo apt install -y python3-fuzzywuzzy
                pip install netaddr selenium requests beautifulsoup4 pillow tldextract ipwhois validators python-whois psutil
                sudo apt-get install eyewitness -y
                spinner 15
                echo "Eyewitness instalado correctamente."
            else
                echo "No se instalará Eyewitness. Abortando análisis."
                exit 1
            fi
        fi
        ;;

    correo)
        read -p "Introduce el correo electrónico: " valor
        echo "Buscando el correo: $valor"
        spinner 10

        if [ -d Zehef ]; then
            cd Zehef || exit 1
            python3 zehef.py "$valor" > ../resultadosZehef_"$valor"
            echo "Resultados guardados en resultadosZehef_$valor"
        else
            echo "Zehef no está instalado"
            read -p "¿Quieres instalar Zehef? (s/n): " respuesta
            if [[ "$respuesta" =~ ^[sS] ]]; then
                echo "Instalando Zehef..."
                sudo apt update
                sudo apt install python3 python3-pip git -y
                git clone https://github.com/N0rz3/Zehef.git
                cd Zehef || exit 1
                spinner 15
            else
                echo "No se instalará Zehef"
                exit 1
            fi
        fi
        ;;

    imagen)
        read -p "Introduce el archivo de la imagen: " valor
        if [[ "$valor" != *.jpg && "$valor" != *.png ]]; then
            echo "Error: el archivo dado no es una imagen"
        fi
        spinner 5

        if exiftool -ver >/dev/null 2>&1; then
            echo "Analizando los metadatos de la imagen '$valor'..."
            exiftool "$valor" > resultado_metadatos
            echo "Metadatos de la imagen guardados en resultado_metadatos"
            cat resultado_metadatos
        else
            read -p "¿Quieres instalar exiftool ahora? (s/n): " respuesta
            if [[ "$respuesta" =~ ^[Ss] ]]; then
                echo "Instalando exiftool..."
                sudo apt update
                sudo apt install libimage-exiftool-perl -y
                spinner 5
                echo "Exiftool instalado correctamente"
            fi
        fi
        ;;

    telefono)
        read -p "Introduce el número de teléfono (prefijo+num, ej: +34643...): " valor
        echo "Analizando el teléfono '$valor'..."
        spinner 10
        curl -s -G "https://whocalld.com/$valor" | lynx -stdin -dump > Resultado_telefono
        echo "Resultado guardado en Resultado_telefono"
        cat Resultado_telefono
        ;;

    ip)
        read -p "Introduce la dirección IP: " valor
        if [[ "$valor" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            echo "Analizando la IP '$valor'..."
            spinner 5
            curl "http://ipwho.is/$valor" | jq . > Resultados_ip
            echo "Resultado guardado en Resultados_ip"
        else
            echo "$valor no es una IP válida"
            exit 1
        fi

        read -p "¿Quieres ver el fichero con la salida? (s/n): " respuesta
        if [[ "$respuesta" =~ ^[sS] ]]; then
            bat Resultados_ip -l java
        else
            exit 1
        fi
        ;;

    *)
        echo "Opción no válida. Debes escribir: usuario, dominio, correo, imagen, telefono o ip."
        exit 1
        ;;
esac
