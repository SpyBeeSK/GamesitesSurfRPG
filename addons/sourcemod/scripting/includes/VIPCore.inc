/*
**
*/
#if defined vip_included
#endinput
#endif
#define vip_included

/**
 * Check if player is a VIP
 *
 * @param client	     Player to check
 * Returns true/false
 */
 native bool VIP_IsVIP(int client);
 
 
public SharedPlugin __plvip = 
{
	name = "VIPCore", 
	file = "VIPCore.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};
#if !defined REQUIRE_PLUGIN
public __plvip_SetNTVOptional()
{
	MarkNativeAsOptional("");
}
#endif