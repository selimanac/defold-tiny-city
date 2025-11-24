
#define LIB_NAME "ProjectPath"
#define MODULE_NAME "project_path"

// include the Defold SDK
#include <dmsdk/sdk.h>

#if defined(_WIN32)
#include <direct.h>
#include <limits.h>
#define GetCWD _getcwd
#define PATH_MAX _MAX_PATH
#else
#include <unistd.h>
#include <limits.h>
#define GetCWD getcwd
#endif

#include <string.h>

static int GetProjectRoot(lua_State* L)
{
    char path[PATH_MAX];
    if (GetCWD(path, sizeof(path)) == NULL)
    {
        lua_pushnil(L);
        return 1;
    }

    // Normalize Windows backslashes
#if defined(_WIN32)
    for (char* p = path; *p; ++p)
        if (*p == '\\')
            *p = '/';
#endif

    // Remove trailing slash
    size_t len = strlen(path);
    if (len > 0 && path[len - 1] == '/')
        path[len - 1] = '\0';

    // If the last directory is "build", remove it
    char* last_slash = strrchr(path, '/');
    if (last_slash)
    {
        const char* last_dir = last_slash + 1;
        if (strcmp(last_dir, "build") == 0)
            *last_slash = '\0';
    }

    lua_pushstring(L, path);
    return 1;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] = { { "get", GetProjectRoot }, { 0, 0 } };

static void           LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result InitializeProjectPath(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(ProjectPath, LIB_NAME, 0, 0, InitializeProjectPath, 0, 0, 0)
