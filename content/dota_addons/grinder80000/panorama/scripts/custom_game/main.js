// $('#skills').childNodes()

function UseSkill(skill) {
    $.Msg('Using skill ', skill);

    var player_id = Players.GetLocalPlayer();

    //Players.GetPlayerHeroEntityIndex();
    var selected_entities_ids = Players.GetSelectedEntities(player_id);
    if(selected_entities_ids.length) {
        var caster_id = selected_entities_ids[0];
        var ability_id = Entities.GetAbilityByName(caster_id, skill);
        $.Msg('CASTER', caster_id, 'SKILL', ability_id);

        if (Game.IsInAbilityLearnMode()) {
            Abilities.AttemptToUpgrade(ability_id);
        } else {
            $.Msg('Mana: ', Entities.GetMana(caster_id));

            Abilities.ExecuteAbility(ability_id, caster_id, false);
        }
    }

    //Abilities.ExecuteAbility();
    //Entities.GetAbilityCount();
};


function getCurrentEntityID() {
    var player_id = Players.GetLocalPlayer();
    var selected_entities_ids = Players.GetSelectedEntities(player_id);
    if (selected_entities_ids.length) {
        return selected_entities_ids[0];
    } else {
        return null;
    }
}

function getAbilities(entityID) {
    var abilities = [];
    var count = Entities.GetAbilityCount(entityID);
    for (var i = 0; i < count; i++) {
        var abilityID = Entities.GetAbility(entityID, i);

        ability = {};

        ability.name = Abilities.GetAbilityName(abilityID);
        if (ability.name) {
            ability.level = Abilities.GetLevel(abilityID);
            ability.manacost = Abilities.GetManaCost(abilityID);
            ability.canBeUpgraded = Abilities.CanAbilityBeUpgraded(abilityID) == AbilityLearnResult_t.ABILITY_CAN_BE_UPGRADED;
            ability.key = Abilities.GetKeybind(abilityID);
    //        ability.cooldown = Abilities.GetCooldownTime(abilityID);
    //        ability.cooldownRemaining = Abilities.GetCooldownTimeRemaining(abilityID);
            abilities.push(ability);
        }
    }
    return abilities;
}


function getBars(entityID) {
    return {
        HP: Entities.GetHealth(entityID),
        maxHP: Entities.GetMaxHealth(entityID),
        MP: Entities.GetMana(entityID),
        maxMP: Entities.GetMaxMana(entityID),
    };
}

function getStats(entityID) {
    return {
        level: Entities.GetLevel(entityID),
        points: Entities.GetAbilityPoints(entityID)
    }
}

function getItems(entityID) {
    var items = [];
    for (var i = 0; i < 6; i++) {
        var itemID = Entities.GetItemInSlot(entityID, i);
        var item;

        if (itemID != -1) {
            item = {
                id: itemID,
                canBeExecuted: Items.CanBeExecuted(itemID) == -1,
                charges: Items.GetCurrentCharges(itemID),
                manacost: Abilities.GetManaCost(itemID),
            };
        } else {
            item = null;
        }
        items.push(item);
    }
    return items;
}

var $hp = $('#hp');
var $hp_max = $('#hp-max');
var $mp = $('#mp');
var $mp_max = $('#mp-max');

var $skills = $('#skills');

var $abilities = [
    $('#pure_skill_wr_projectile'),
    $('#pure_skill_wr_block'),
    $('#pure_skill_wr_rush'),
];

var $abilitiesManaCosts = [
    $('#pure_skill_wr_projectile_manacost'),
    $('#pure_skill_wr_block_manacost'),
    $('#pure_skill_wr_rush_manacost'),
];

var $abilitiesLevels = [
    $('#pure_skill_wr_projectile_level'),
    $('#pure_skill_wr_block_level'),
    $('#pure_skill_wr_rush_level'),
];

var $abilitiesKeys = [
    $('#pure_skill_wr_projectile_key'),
    $('#pure_skill_wr_block_key'),
    $('#pure_skill_wr_rush_key'),
];

var $learn = $('#upgrade-skills');

var $level = $('#level');

function updateGUI() {
    var entityID = getCurrentEntityID();

    if (entityID) {
        var bars = getBars(entityID);
        var abilities = getAbilities(entityID);
        var stats = getStats(entityID);
        var items = getItems(entityID);

        var hpFactor = bars.HP / bars.maxHP;
        var mpFactor = bars.MP / bars.maxMP;

        $hp.style.width = Math.ceil(hpFactor * 575) + 'px';
        $mp.style.width = Math.ceil(mpFactor * 575) + 'px';

        $hp_max.text = bars.HP + ' / ' + bars.maxHP;
        $mp_max.text = bars.MP + ' / ' + bars.maxMP;

        for(var i = 0; i < abilities.length; i++) {
            var ability = abilities[i];
            if (ability.level == 0) {
                $abilities[i].AddClass('disabled');

                $abilitiesManaCosts[i].text = '-';
            } else {
                $abilities[i].RemoveClass('disabled');

                $abilitiesManaCosts[i].text = ability.manacost;
                $abilitiesLevels[i].text = ability.level + '/4';

                $abilitiesKeys[i].text = ability.key;

                if (ability.manacost > bars.MP) {
                    $abilities[i].AddClass('nomana');
                } else {
                    $abilities[i].RemoveClass('nomana');
                }
            }

            if (Game.IsInAbilityLearnMode() && ability.canBeUpgraded) {
                $abilities[i].AddClass('CanUpgrade');
            } else {
                $abilities[i].RemoveClass('CanUpgrade');
            }
        }

        if (stats.points) {
            $learn.AddClass('Visible');
        } else {
            $learn.RemoveClass('Visible');
            Game.EndAbilityLearnMode();
        }

        $level.text = stats.level;
    }

    $.Schedule(0.033, updateGUI);

//    $.$$.test();
}

function switchLearnMode() {
    if (!Game.IsInAbilityLearnMode()) {
        $.Msg('ENTER');
        Game.EnterAbilityLearnMode();
    } else {
        $.Msg('EXIT');
        Game.EndAbilityLearnMode();
    }
}

(function() {
    $.Msg('Panorama ready');
    updateGUI();

//    $.Msg(':: ' + $skills);
//    for (var childKey in $skills.Children()) {
//        $.Msg(childKey + ' -> ' + $skills.Children()[childKey]);
//        $.Msg($skills.GetChild(parseInt(childKey)).SetAttributeString('class', 'azaza'));
//        $.Msg($skills.GetChild(parseInt(childKey)).GetAttributeString('class', '???'));
//    }
})();
