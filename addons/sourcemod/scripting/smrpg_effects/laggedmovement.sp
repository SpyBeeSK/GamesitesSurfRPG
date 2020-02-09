/**
 * This file is part of the SM:RPG Effect Hub.
 * Handles changing of the lagged movement of players.
 */

Handle g_hfwdOnClientLaggedMovementChange;
Handle g_hfwdOnClientLaggedMovementChanged;
Handle g_hfwdOnClientLaggedMovementReset;

enum MovementState {
	Float:MS_slower,
	Float:MS_faster,
	Handle:MS_lastSlowPlugin,
	Handle:MS_lastFastPlugin
};

int g_ClientMovementState[MAXPLAYERS+1][MovementState];
Handle g_hSlowRestoreTimer[MAXPLAYERS+1];
Handle g_hFastRestoreTimer[MAXPLAYERS+1];

/**
 * Setup helpers
 */
void RegisterLaggedMovementNatives()
{
	CreateNative("SMRPG_ChangeClientLaggedMovement", Native_ChangeClientLaggedMovement);
	CreateNative("SMRPG_ResetClientLaggedMovement", Native_ResetClientLaggedMovement);
	CreateNative("SMRPG_IsClientLaggedMovementChanged", Native_IsClientLaggedMovementChanged);
}

void RegisterLaggedMovementForwards()
{
	// forward Action SMRPG_OnClientLaggedMovementChange(client, LaggedMovementType:type, &float fTime);
	g_hfwdOnClientLaggedMovementChange = CreateGlobalForward("SMRPG_OnClientLaggedMovementChange", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	// forward SMRPG_OnClientLaggedMovementChanged(client, LaggedMovementType:type, float fTime);
	g_hfwdOnClientLaggedMovementChanged = CreateGlobalForward("SMRPG_OnClientLaggedMovementChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	// forward SMRPG_OnClientLaggedMovementReset(client, LaggedMovementType:type);
	g_hfwdOnClientLaggedMovementReset = CreateGlobalForward("SMRPG_OnClientLaggedMovementReset", ET_Ignore, Param_Cell, Param_Cell);
}

void ResetLaggedMovementClient(int client)
{
	if(IsClientInGame(client))
	{
		if(g_ClientMovementState[client][MS_faster] > 0.0)
			ResetSpeedUp(client);
		if(g_ClientMovementState[client][MS_slower] > 0.0)
			ResetSlowDown(client);
	}
	ClearHandle(g_hFastRestoreTimer[client]);
	ClearHandle(g_hSlowRestoreTimer[client]);
	
	g_ClientMovementState[client][MS_slower] = 0.0;
	g_ClientMovementState[client][MS_faster] = 0.0;
	g_ClientMovementState[client][MS_lastSlowPlugin] = null;
	g_ClientMovementState[client][MS_lastFastPlugin] = null;
}

/**
 * Timer callbacks
 */
public Action Timer_OnResetSlowdown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	g_hSlowRestoreTimer[client] = null;
	
	// Reset the effect
	ResetSlowDown(client);
	
	return Plugin_Stop;
}

public Action Timer_OnResetSpeedup(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	g_hFastRestoreTimer[client] = null;
	
	// Reset the effect
	ResetSpeedUp(client);
	
	return Plugin_Stop;
}


/**
 * Native callbacks
 */
// native bool SMRPG_ChangeClientLaggedMovement(int client, float fValue, float fTime);
public int Native_ChangeClientLaggedMovement(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(client <= 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	float fValue = view_as<float>(GetNativeCell(2));
	float fTime = view_as<float>(GetNativeCell(3));
	
	if(fValue < 0.0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid negative value for m_flLaggedMovementValue: %f", fValue);
	
	if(fTime <= 0.0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid effect time: %f", fTime);
	
	if(fValue == 1.0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Can't set value to 1.0 here. Use SMRPG_ResetClientLaggedMovement!");
	
	// Slowing the player down
	if(fValue < 1.0)
	{
		float fSlowdown = 1.0 - fValue;
		
		Action ret;
		Call_StartForward(g_hfwdOnClientLaggedMovementChange);
		Call_PushCell(client);
		Call_PushCell(LMT_Slower);
		Call_PushFloatRef(fTime);
		Call_Finish(ret);
		
		if(ret >= Plugin_Handled)
			return false;
		
		// Already slower? Ignore this effect.
		if(g_ClientMovementState[client][MS_slower] >= fSlowdown)
			return false;
		
		// Are you insane?
		if(fTime <= 0.0)
			return ThrowNativeError(SP_ERROR_NATIVE, "Invalid effect time %f.", fTime);
		
		g_ClientMovementState[client][MS_slower] = fSlowdown;
		g_ClientMovementState[client][MS_lastSlowPlugin] = plugin;
		
		// Do the correct new speed.
		ApplyLaggedMovementValue(client);
		
		// Make sure we reset the speed after some time.
		ClearHandle(g_hSlowRestoreTimer[client]);
		g_hSlowRestoreTimer[client] = CreateTimer(fTime, Timer_OnResetSlowdown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		// Inform that the speed was changed.
		Call_StartForward(g_hfwdOnClientLaggedMovementChanged);
		Call_PushCell(client);
		Call_PushCell(LMT_Slower);
		Call_PushFloat(fTime);
		Call_Finish();
	}
	// Speeding the player up.
	else
	{
		float fSpeedup = fValue - 1.0;
		
		Action ret;
		Call_StartForward(g_hfwdOnClientLaggedMovementChange);
		Call_PushCell(client);
		Call_PushCell(LMT_Faster);
		Call_PushFloatRef(fTime);
		Call_Finish(ret);
		
		if(ret >= Plugin_Handled)
			return false;
		
		// Already faster? Ignore this effect.
		if(g_ClientMovementState[client][MS_faster] >= fSpeedup)
			return false;
		
		// Are you insane?
		if(fTime <= 0.0)
			return ThrowNativeError(SP_ERROR_NATIVE, "Invalid effect time %f.", fTime);
		
		g_ClientMovementState[client][MS_faster] = fSpeedup;
		g_ClientMovementState[client][MS_lastFastPlugin] = plugin;
		
		// Do the correct new speed.
		ApplyLaggedMovementValue(client);
		
		// Make sure we reset the speed after some time.
		ClearHandle(g_hFastRestoreTimer[client]);
		g_hFastRestoreTimer[client] = CreateTimer(fTime, Timer_OnResetSpeedup, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		// Inform that the speed was changed.
		Call_StartForward(g_hfwdOnClientLaggedMovementChanged);
		Call_PushCell(client);
		Call_PushCell(LMT_Faster);
		Call_PushFloat(fTime);
		Call_Finish();
	}
	
	return true;
}

// native bool SMRPG_ResetClientLaggedMovement(int client, LaggedMovementType type, bool bForce=false);
public int Native_ResetClientLaggedMovement(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(client <= 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	LaggedMovementType type = view_as<LaggedMovementType>(GetNativeCell(2));
	bool bForce = view_as<bool>(GetNativeCell(3));
	
	switch(type)
	{
		case LMT_Slower:
		{
			// Player is not slowed down?
			if(g_ClientMovementState[client][MS_slower] == 0.0)
				return false;
			
			// Slowed down by some other plugin.
			if(g_ClientMovementState[client][MS_lastSlowPlugin] != plugin && !bForce)
				return false;
			
			// Reset the speed.
			g_ClientMovementState[client][MS_slower] = 0.0;
			g_ClientMovementState[client][MS_lastSlowPlugin] = null;
		}
		case LMT_Faster:
		{
			// Player is not sped up?
			if(g_ClientMovementState[client][MS_faster] == 0.0)
				return false;
			
			// Sped up by some other plugin.
			if(g_ClientMovementState[client][MS_lastFastPlugin] != plugin && !bForce)
				return false;
			
			// Reset the speed.
			g_ClientMovementState[client][MS_faster] = 0.0;
			g_ClientMovementState[client][MS_lastFastPlugin] = null;
		}
		default:
		{
			return ThrowNativeError(SP_ERROR_NATIVE, "Unknown type %d", type);
		}
	}
	
	ApplyLaggedMovementValue(client);
	
	return true;
}

// native bool SMRPG_IsClientLaggedMovementChanged(int client, LaggedMovementType type, bool bByMe=false);
public int Native_IsClientLaggedMovementChanged(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(client <= 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	LaggedMovementType type = view_as<LaggedMovementType>(GetNativeCell(2));
	bool bByMe = view_as<bool>(GetNativeCell(3));
	
	switch(type)
	{
		case LMT_Slower:
		{
			// Player is not slowed down?
			if(g_ClientMovementState[client][MS_slower] == 0.0)
				return false;
			
			// Slowed down by some other plugin.
			if(g_ClientMovementState[client][MS_lastSlowPlugin] != plugin && bByMe)
				return false;
		}
		case LMT_Faster:
		{
			// Player is not sped up?
			if(g_ClientMovementState[client][MS_faster] == 0.0)
				return false;
			
			// Sped up by some other plugin.
			if(g_ClientMovementState[client][MS_lastFastPlugin] != plugin && bByMe)
				return false;
		}
		default:
		{
			return ThrowNativeError(SP_ERROR_NATIVE, "Unknown type %d", type);
		}
	}
	
	return true;
}

/**
 * Helpers
 */
stock void ApplyLaggedMovementValue(int client)
{
	float fSlow = g_ClientMovementState[client][MS_slower];
	float fFast = g_ClientMovementState[client][MS_faster];
	
	float fValue = (1.0 - fSlow) + fFast;
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fValue);
}

void ResetSlowDown(int client)
{
	// Reset the effect
	g_ClientMovementState[client][MS_slower] = 0.0;
	g_ClientMovementState[client][MS_lastSlowPlugin] = null;
	
	ApplyLaggedMovementValue(client);
	
	Call_StartForward(g_hfwdOnClientLaggedMovementReset);
	Call_PushCell(client);
	Call_PushCell(LMT_Slower);
	Call_Finish();
}

void ResetSpeedUp(int client)
{
	// Reset the effect
	g_ClientMovementState[client][MS_faster] = 0.0;
	g_ClientMovementState[client][MS_lastFastPlugin] = null;
	
	ApplyLaggedMovementValue(client);
	
	Call_StartForward(g_hfwdOnClientLaggedMovementReset);
	Call_PushCell(client);
	Call_PushCell(LMT_Faster);
	Call_Finish();
}