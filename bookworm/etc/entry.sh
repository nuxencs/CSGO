#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login anonymous \
				+app_update "${STEAMAPPID}" \
				+quit

# Are we in a metamod container and is the metamod folder missing?
if  [ ! -z "$METAMOD_VERSION" ] && [ ! -d "${STEAMAPPDIR}/${STEAMAPP}/addons/metamod" ]; then
	LATESTMM=$(wget -qO- https://mms.alliedmods.net/mmsdrop/"${METAMOD_VERSION}"/mmsource-latest-linux)
	wget -qO- https://mms.alliedmods.net/mmsdrop/"${METAMOD_VERSION}"/"${LATESTMM}" | tar xvzf - -C "${STEAMAPPDIR}/${STEAMAPP}"
fi

# Are we in a sourcemod container and is the sourcemod folder missing?
if  [ ! -z "$SOURCEMOD_VERSION" ] && [ ! -d "${STEAMAPPDIR}/${STEAMAPP}/addons/sourcemod" ]; then
	LATESTSM=$(wget -qO- https://sm.alliedmods.net/smdrop/"${SOURCEMOD_VERSION}"/sourcemod-latest-linux)
	wget -qO- https://sm.alliedmods.net/smdrop/"${SOURCEMOD_VERSION}"/"${LATESTSM}" | tar xvzf - -C "${STEAMAPPDIR}/${STEAMAPP}"
fi

# Install NoLobbyReservation
if  [ ! -z "$SOURCEMOD_VERSION" ] && [ ! -f "${STEAMAPPDIR}/${STEAMAPP}/addons/sourcemod/plugins/nolobbyreservation.smx"]; then
	wget -qO nlr.zip https://github.com/nuxencs/NoLobbyReservation/releases/latest/download/NoLobbyReservation.zip && \
	unzip -d "${STEAMAPPDIR}/${STEAMAPP}" nlr.zip && \
	rm nlr.zip
fi

# Install PTaH
if  [ ! -z "$SOURCEMOD_VERSION" ] && [ "$SKIN_PLUGINS" == "true" ] && [ ! -f "${STEAMAPPDIR}/${STEAMAPP}/addons/sourcemod/extensions/PTaH.ext.2.csgo.so"]; then
	wget -qO ptah.zip $(curl -s https://api.github.com/repos/komashchenko/PTaH/releases/latest | grep download | grep linux | cut -d\" -f4) && \
	unzip -d "${STEAMAPPDIR}/${STEAMAPP}" ptah.zip && \
	rm ptah.zip
fi

# Install Weapons
if  [ ! -z "$SOURCEMOD_VERSION" ] && [ "$SKIN_PLUGINS" == "true" ] && [ ! -f "${STEAMAPPDIR}/${STEAMAPP}/addons/sourcemod/plugins/weapons.smx"]; then
	wget -qO wpns.zip $(curl -s https://api.github.com/repos/kgns/weapons/releases/latest | grep download | grep weapons | cut -d\" -f4) && \
	unzip -d "${STEAMAPPDIR}/${STEAMAPP}" wpns.zip && \
	rm wpns.zip

	# Remove prefix & set float increment size
	sed -i -e 's:sm_weapons_chat_prefix "[oyunhost.net]":sm_weapons_chat_prefix "":g' "${STEAMAPPDIR}/${STEAMAPP}/cfg/sourcemod/weapons.cfg"
	sed -i -e 's:sm_weapons_float_increment_size "0.05":sm_weapons_float_increment_size "0.01":g' "${STEAMAPPDIR}/${STEAMAPP}/cfg/sourcemod/weapons.cfg"
fi

# Install Gloves
if  [ ! -z "$SOURCEMOD_VERSION" ] && [ "$SKIN_PLUGINS" == "true" ] && [ ! -f "${STEAMAPPDIR}/${STEAMAPP}/addons/sourcemod/plugins/gloves.smx"]; then
	wget -qO glvs.zip $(curl -s https://api.github.com/repos/kgns/gloves/releases/latest | grep download | grep gloves | cut -d\" -f4) && \
	unzip -d "${STEAMAPPDIR}/${STEAMAPP}" glvs.zip && \
	rm glvs.zip

	# Remove prefix & set float increment size
	sed -i -e 's:sm_gloves_chat_prefix "[oyunhost.net]":sm_gloves_chat_prefix "":g' "${STEAMAPPDIR}/${STEAMAPP}/cfg/sourcemod/gloves.cfg"
	sed -i -e 's:sm_gloves_float_increment_size "0.2":sm_gloves_float_increment_size "0.01":g' "${STEAMAPPDIR}/${STEAMAPP}/cfg/sourcemod/gloves.cfg"
fi

# Changing FollowCSGOServerGuidelines to "no" for skin plugins
if  [ ! -z "$SOURCEMOD_VERSION" ] && [ "$SKIN_PLUGINS" == "true" ]; then
	sed -i -e 's:"FollowCSGOServerGuidelines"\t"yes":"FollowCSGOServerGuideLines"\t"no":g' "${STEAMAPPDIR}/${STEAMAPP}/addons/sourcemod/configs/core.cfg"
fi

# Is the config missing?
if [ ! -f "${STEAMAPPDIR}/${STEAMAPP}/cfg/server.cfg" ]; then
	# overwrite the base config files with the baked in ones
	cp -r /etc/csgo/* "${STEAMAPPDIR}/${STEAMAPP}/cfg"

	# Change hostname on first launch (you can comment this out if it has done its purpose)
	sed -i -e 's/{{SERVER_HOSTNAME}}/'"${SRCDS_HOSTNAME}"'/g' "${STEAMAPPDIR}/${STEAMAPP}/cfg/server.cfg"
fi

# Believe it or not, if you don't do this srcds_run shits itself
cd "${STEAMAPPDIR}"

# Check if autoexec file exists
# Passing arguments directly to srcds_run, ignores values set in autoexec.cfg
autoexec_file="${STEAMAPPDIR}/${STEAMAPP}/cfg/autoexec.cfg"

# Overwritable arguments
ow_args=""

# If you need to overwrite a specific launch argument, add it to this loop and drop it from the subsequent srcds_run call
if [ -f "$autoexec_file" ]; then
        # TAB delimited name    default
        # HERE doc to not add extra file
        while IFS=$'\t' read -r name default
        do
                if ! grep -q "^\s*$name" "$autoexec_file"; then
                        ow_args="${ow_args} $default"
                fi
        done <<EOM
sv_password	+sv_password "${SRCDS_PW}"
rcon_password	+rcon_password "${SRCDS_RCONPW}"
EOM
	# if autoexec is present, drop overwritten arguments here (example: SRCDS_PW & SRCDS_RCONPW)
	bash "${STEAMAPPDIR}/srcds_run" -game "${STEAMAPP}" -console \
				-steam_dir "${STEAMCMDDIR}" \
				-steamcmd_script "${HOMEDIR}/${STEAMAPP}_update.txt" \
				-usercon \
				+fps_max "${SRCDS_FPSMAX}" \
				-tickrate "${SRCDS_TICKRATE}" \
				-port "${SRCDS_PORT}" \
				+tv_port "${SRCDS_TV_PORT}" \
				+clientport "${SRCDS_CLIENT_PORT}" \
				-maxplayers_override "${SRCDS_MAXPLAYERS}" \
				+game_type "${SRCDS_GAMETYPE}" \
				+game_mode "${SRCDS_GAMEMODE}" \
				+mapgroup "${SRCDS_MAPGROUP}" \
				+map "${SRCDS_STARTMAP}" \
				+sv_setsteamaccount "${SRCDS_TOKEN}" \
				+sv_region "${SRCDS_REGION}" \
				+net_public_adr "${SRCDS_NET_PUBLIC_ADDRESS}" \
				-ip "${SRCDS_IP}" \
				+sv_lan "${SRCDS_LAN}" \
				+host_workshop_collection "${SRCDS_HOST_WORKSHOP_COLLECTION}" \
				+workshop_start_map "${SRCDS_WORKSHOP_START_MAP}" \
				-authkey "${SRCDS_WORKSHOP_AUTHKEY}" \
				"${ow_args}" \
				"${ADDITIONAL_ARGS}"
else
	# If no autoexec is present, use all parameters
	bash "${STEAMAPPDIR}/srcds_run" -game "${STEAMAPP}" -console \
				-steam_dir "${STEAMCMDDIR}" \
				-steamcmd_script "${HOMEDIR}/${STEAMAPP}_update.txt" \
				-usercon \
				+fps_max "${SRCDS_FPSMAX}" \
				-tickrate "${SRCDS_TICKRATE}" \
				-port "${SRCDS_PORT}" \
				+tv_port "${SRCDS_TV_PORT}" \
				+clientport "${SRCDS_CLIENT_PORT}" \
				-maxplayers_override "${SRCDS_MAXPLAYERS}" \
				+game_type "${SRCDS_GAMETYPE}" \
				+game_mode "${SRCDS_GAMEMODE}" \
				+mapgroup "${SRCDS_MAPGROUP}" \
				+map "${SRCDS_STARTMAP}" \
				+sv_setsteamaccount "${SRCDS_TOKEN}" \
				+rcon_password "${SRCDS_RCONPW}" \
				+sv_password "${SRCDS_PW}" \
				+sv_region "${SRCDS_REGION}" \
				+net_public_adr "${SRCDS_NET_PUBLIC_ADDRESS}" \
				-ip "${SRCDS_IP}" \
				+sv_lan "${SRCDS_LAN}" \
				+host_workshop_collection "${SRCDS_HOST_WORKSHOP_COLLECTION}" \
				+workshop_start_map "${SRCDS_WORKSHOP_START_MAP}" \
				-authkey "${SRCDS_WORKSHOP_AUTHKEY}" \
				"${ADDITIONAL_ARGS}"
fi
