# show death cause of a creature
=begin

deathcause
==========
Select a body part ingame, or a unit from the :kbd:`u` unit list, and this
script will display the cause of death of the creature.

=end

def display_death_event(e)
    str = "The #{e.victim_hf_tg.race_tg.name[0]} #{e.victim_hf_tg.name} died in year #{e.year}"
    str << " (cause: #{e.death_cause.to_s.downcase}),"
    str << " killed by the #{e.slayer_race_tg.name[0]} #{e.slayer_hf_tg.name}" if e.slayer_hf != -1
    str << " using a #{df.world.raws.itemdefs.weapons[e.weapon.item_subtype].name}" if e.weapon.item_type == :WEAPON
    str << ", shot by a #{df.world.raws.itemdefs.weapons[e.weapon.shooter_item_subtype].name}" if e.weapon.shooter_item_type == :WEAPON

    puts str.chomp(',') + '.'
end

def display_death_unit(u)
    str = "The #{u.race_tg.name[0]}"
    str << " #{u.name}" if u.name.has_name

    if not u.flags2.killed and not u.flags3.ghostly
        str << " is not dead yet !"

        puts str.chomp(',')
    else
        death_info = u.counters.death_tg
        killer = death_info.criminal_tg if death_info

        str << " died" if !u.flags2.slaughter
        str << " was slaughtered" if u.flags2.slaughter

        str << " in year #{death_info.event_year}" if death_info
        str << " (cause: #{u.counters.death_cause.to_s.downcase})," if u.counters.death_cause != -1
        str << " killed by the #{killer.race_tg.name[0]} #{killer.name}" if killer

        puts str.chomp(',') + '.'
    end
end

item = df.item_find(:selected)
unit = df.unit_find(:selected)

if !unit and (!item or !item.kind_of?(DFHack::ItemBodyComponent))
    item = df.world.items.other[:ANY_CORPSE].find { |i| df.at_cursor?(i) }
end

if item and item.kind_of?(DFHack::ItemBodyComponent)
    hf = item.hist_figure_id
elsif unit
    hf = unit.hist_figure_id
end

if not hf
    puts "Please select a corpse in the loo'k' menu, or an unit in the 'u'nitlist screen"

elsif hf == -1
    if unit ||= item.unit_tg
        display_death_unit(unit)
    else
        puts "Not a historical figure, cannot find death info"
    end

else
    histfig = df.world.history.figures.binsearch(hf)
    unit = histfig ? df.unit_find(histfig.unit_id) : nil
    if unit and not unit.flags2.killed and not unit.flags3.ghostly
        puts "#{unit.name} is not dead yet !"

    else
        events = df.world.history.events
        (0...events.length).reverse_each { |i|
            e = events[i]
            if e.kind_of?(DFHack::HistoryEventHistFigureDiedst) and e.victim_hf == hf
                display_death_event(e)
                break
            end
        }
    end
end
