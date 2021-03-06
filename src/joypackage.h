#ifndef JOYPACKAGE_H
#define JOYPACKAGE_H

#include "package.h"
#include "standard.h"

class JoyPackage: public Package{
    Q_OBJECT

public:
    JoyPackage();
};

class Shit:public BasicCard{
    Q_OBJECT

public:
    Q_INVOKABLE Shit(Card::Suit suit, int number);
    virtual QString getSubtype() const;
    virtual void onMove(const CardMoveStruct &move) const;

    static bool HasShit(const Card *card);
};

// five disasters:

class Deluge: public Disaster{
    Q_OBJECT

public:
    Q_INVOKABLE Deluge(Card::Suit suit, int number);
    virtual void takeEffect(ServerPlayer *target) const;
};

class Typhoon: public Disaster{
    Q_OBJECT

public:
    Q_INVOKABLE Typhoon(Card::Suit suit, int number);
    virtual void takeEffect(ServerPlayer *target) const;
};

class Earthquake: public Disaster{
    Q_OBJECT

public:
    Q_INVOKABLE Earthquake(Card::Suit suit, int number);
    virtual void takeEffect(ServerPlayer *target) const;
};

class Volcano: public Disaster{
    Q_OBJECT

public:
    Q_INVOKABLE Volcano(Card::Suit suit, int number);
    virtual void takeEffect(ServerPlayer *target) const;
};

class MudSlide: public Disaster{
    Q_OBJECT

public:
    Q_INVOKABLE MudSlide(Card::Suit suit, int number);
    virtual void takeEffect(ServerPlayer *target) const;
};

#endif // JOYPACKAGE_H
