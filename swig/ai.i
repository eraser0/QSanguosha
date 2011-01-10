%{

#include "ai.h"
#include "joypackage.h"

%}

class AI: public QObject{
public:
    AI(ServerPlayer *player);

    enum Relation { Friend, Enemy, Neutrality };
    Relation relationTo(const ServerPlayer *other) const;
    bool isFriend(const ServerPlayer *other) const;
    bool isEnemy(const ServerPlayer *other) const;

    SPlayerList getEnemies() const;
    SPlayerList getFriends() const;

    virtual void activate(CardUseStruct &card_use) = 0;
    virtual Card::Suit askForSuit() = 0;
    virtual QString askForKingdom() = 0;
    virtual bool askForSkillInvoke(const QString &skill_name, const QVariant &data) = 0;
    virtual QString askForChoice(const QString &skill_name, const QString &choices) = 0;
    virtual QList<int> askForDiscard(int discard_num, bool optional, bool include_equip) = 0;
    virtual int askForNullification(const QString &trick_name, ServerPlayer *from, ServerPlayer *to)  = 0;
    virtual int askForCardChosen(ServerPlayer *who, const QString &flags, const QString &reason)  = 0;
    virtual const Card *askForCard(const QString &pattern)  = 0;
    virtual QString askForUseCard(const QString &pattern, const QString &prompt)  = 0;
    virtual int askForAG(const QList<int> &card_ids, bool refsuable) = 0;
    virtual const Card *askForCardShow(ServerPlayer *requestor) = 0;
    virtual const Card *askForPindian() = 0;
    virtual ServerPlayer *askForPlayerChosen(const SPlayerList &targets) = 0;
    virtual const Card *askForSinglePeach(ServerPlayer *dying) = 0;
};

class TrustAI: public AI{
public:
    TrustAI(ServerPlayer *player);

    virtual void activate(CardUseStruct &card_use) ;
    virtual Card::Suit askForSuit() ;
    virtual QString askForKingdom() ;
    virtual bool askForSkillInvoke(const QString &skill_name, const QVariant &data) ;
    virtual QString askForChoice(const QString &skill_name, const QString &choices);
    virtual QList<int> askForDiscard(int discard_num, bool optional, bool include_equip) ;
    virtual int askForNullification(const QString &trick_name, ServerPlayer *from, ServerPlayer *to) ;
    virtual int askForCardChosen(ServerPlayer *who, const QString &flags, const QString &reason) ;
    virtual const Card *askForCard(const QString &pattern) ;
    virtual QString askForUseCard(const QString &pattern, const QString &prompt) ;
    virtual int askForAG(const QList<int> &card_ids, bool refsuable);
    virtual const Card *askForCardShow(ServerPlayer *requestor) ;
    virtual const Card *askForPindian() ;
    virtual ServerPlayer *askForPlayerChosen(const SPlayerList &targets) ;
    virtual const Card *askForSinglePeach(ServerPlayer *dying) ;

    virtual bool useCard(const Card *card);
};

class LuaAI: public TrustAI{
public:
    LuaAI(ServerPlayer *player);

    virtual const Card *askForCardShow(ServerPlayer *requestor);
    virtual bool askForSkillInvoke(const QString &skill_name, const QVariant &data);
    virtual void activate(CardUseStruct &card_use);

    LuaFunction callback;
};

// for some AI use
class Shit:public BasicCard{
public:
    Shit(Card::Suit suit, int number);
    virtual QString getSubtype() const;
    virtual void onMove(const CardMoveStruct &move) const;

    static bool HasShit(const Card *card);
};

%{

bool LuaAI::askForSkillInvoke(const QString &skill_name, const QVariant &data) {
    if(callback == 0)
        return TrustAI::askForSkillInvoke(skill_name, data);

    lua_State *L = room->getLuaState();

    lua_rawgeti(L, LUA_REGISTRYINDEX, callback);

    lua_pushstring(L, __func__);

    lua_pushstring(L, skill_name.toAscii());

    SWIG_NewPointerObj(L, &data, SWIGTYPE_p_QVariant, 0);

    int error = lua_pcall(L, 3, 1, 0);
    if(error){
        const char *error_msg = lua_tostring(L, -1);
        lua_pop(L, 1);
        room->output(error_msg);
    }else{
        bool invoke = lua_toboolean(L, -1);
        lua_pop(L, 1);
        return invoke;
    }

    return false;
}

void LuaAI::activate(CardUseStruct &card_use) {
    if(callback == 0){
        return TrustAI::activate(card_use);
    }

    lua_State *L = room->getLuaState();

    lua_rawgeti(L, LUA_REGISTRYINDEX, callback);

    lua_pushstring(L, __func__);

    SWIG_NewPointerObj(L, &card_use, SWIGTYPE_p_CardUseStruct, 0);

    int error = lua_pcall(L, 2, 0, 0);
    if(error){
        const char *error_msg = lua_tostring(L, -1);
        lua_pop(L, 1);
        room->output(error_msg);
    }
}

AI *Room::cloneAI(ServerPlayer *player){
    bool specialized = false;
    switch(Config.AILevel){
    case 0: return new TrustAI(player);
    case 1: break;
    case 2: specialized = true; break;
    }

    lua_getglobal(L, "CloneAI");

    SWIG_NewPointerObj(L, player, SWIGTYPE_p_ServerPlayer, 0);

    lua_pushboolean(L, specialized);

    int error = lua_pcall(L, 2, 1, 0);
    if(error){
        const char *error_msg = lua_tostring(L, -1);
        lua_pop(L, 1);
        output(error_msg);
    }else{
        void *ai_ptr;
        int result = SWIG_ConvertPtr(L, -1, &ai_ptr, SWIGTYPE_p_AI, 0);
        lua_pop(L, 1);
        if(SWIG_IsOK(result)){
            AI *ai = static_cast<AI *>(ai_ptr);
            return ai;
        }
    }

    return new TrustAI(player);
}

ServerPlayer *LuaAI::askForYiji(const QList<int> &cards, int &card_id){
    if(callback == 0)
        return TrustAI::askForYiji(cards, card_id);

    lua_State *L = room->getLuaState();

    lua_rawgeti(L, LUA_REGISTRYINDEX, callback);

    lua_pushstring(L, __func__);

	lua_createtable(L, cards.length(), 0);
	int i;
	for(i=0; i<cards.length(); i++){
		int elem = cards.at(i);
		lua_pushnumber(L, elem);
		lua_rawseti(L, -2, i+1);
	}

    int error = lua_pcall(L, 2, 2, 0);
    if(error){
        const char *error_msg = lua_tostring(L, -1);
        lua_pop(L, 1);
        room->output(error_msg);
        return NULL;
    }

    void *player_ptr;
    int result = SWIG_ConvertPtr(L, -2, &player_ptr, SWIGTYPE_p_ServerPlayer, 0);
    int number = lua_tonumber(L, -1);
    lua_pop(L, 2);

    if(SWIG_IsOK(result)){
        card_id = number;
        return static_cast<ServerPlayer *>(player_ptr);
    }

    return NULL;
}

%}