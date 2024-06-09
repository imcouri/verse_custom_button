
using { /Verse.org/Assets }
using { /Verse.org/Random }


AnimationTypes:= enum{
    None,
    Combat,
    Healing,
    Visual
}

AnimationActionValueTypes:= enum{
    Range,
    Value
}

NPCAnimationData := class():

    # The animation sequence file
    AnimationSequence : animation_sequence

    # The name/alias of the animation
    AnimationName : string

    # The type of animation which determines how the values are used
    AnimationType : AnimationTypes

    # Time stamps which indicate when 'actions' occur in the animation
    AnimationActionTimeStamps : []float = array{}

    # The values associated with the actions
    AnimationActionValues : []float = array{}

    # Determines how the values defined in 'AnimationActionValues' are interpreted (e.g. as a range or a single value)
    AnimationActionValueType : AnimationActionValueTypes = AnimationActionValueTypes.Value


    getAnimationActions():?[float]float=
        # Check if the timestamps and values are defined
        if(TimeStamps := AnimationActionTimeStamps, Values := AnimationActionValues,AnimationActionValueType = AnimationActionValueTypes.Value, TimeStamps.Length > 0, Values.Length > 0):
            # Check if the timestamps and values are of the same length
            if(TimeStamps.Length = Values.Length):
                var OutputActionsMap : [float]float = map{}
                for(i := 0..TimeStamps.Length - 1):
                    # Timestamp
                    if(T := TimeStamps[i]):
                        # Get the value associated with the action
                        V := getAnimaActionValue(i)
                        if:
                            # Add the action to the map
                            set OutputActionsMap[T] = V

                # If any actions were parsed successfully, return the map
                if(OutputActionsMap.Length > 0):
                    return option{OutputActionsMap}

        return false # Return false in any other case


    getAnimaActionValue(Index : int):float=
         # Check if the action values are defined
        if(ActionValues := AnimationActionValues, ValueType := AnimationActionValueType, ActionValues.Length > 0):
            # If the values are defined as a range
            if(ValueType = AnimationActionValueTypes.Range):
                # Check if the range is defined correctly
                if(ActionValues.Length = 2, MinVal := ActionValues[0], MaxVal := ActionValues[1]): 
                    # Get a random value within the range
                    RandomRangedValue : float = GetRandomFloat(MinVal, MaxVal) 
                    # Round the value to the nearest integer
                    if(RoundedValue : int = Floor[RandomRangedValue]): 
                        # Return the rounded value as a float
                        return RoundedValue * 1.0 
            else:
                # Check if the index is within the bounds of the action values
                if(Index >= 0, Index < ActionValues.Length):
                    # Return the value at the index
                    if(ValidValue := ActionValues[Index]):
                        return ValidValue
        return 0.0  # Return 0 in any other case



#EXAMPLE USAGE (JUST FOR DEMONSTRATION PURPOSES, NOT A COMPLETE IMPLEMENTATION)

using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }

NPCAnimations := class():

    # Create a new NPCAnimationData object
    NPCAttackComboAnim : NPCAnimationData = NPCAnimationData{
        AnimationSequence := NPCAnims.Combo,
        AnimationName := "Combo Attack",
        AnimationType := AnimationTypes.Combat,
        AnimationActionTimeStamps := array{0.45, 0.86, 1.2}, # Time stamps in seconds
        AnimationActionValues := array{20.0, 42.0, 110.0}, # Values associated with the actions for each time stamp (Damage values in this case) 
        AnimationActionValueType := AnimationActionValueTypes.Value
    }
    

    playComboAttackAnim(NPCAnimController : play_animation_controller, PlayerAgent : agent)<suspends>:void=
        MaybeComboActions := NPCAttackComboAnim.getAnimationActions() # Get the actions associated with the animation
        # Check if the actions are defined
        if(ComboActions:=MaybeComboActions?):
            # Iterate over the actions
            for(TimeStamp -> Value : ComboActions):
                # Wait for the time stamp
                Sleep(TimeStamp)
                # Play the animation
                NPCAnimController.Play(NPCAttackComboAnim.AnimationSequence)
                # Handle the action
                handleAnimAction(PlayerAgent, AnimationTypes.Combat, Value)
                

    # Apply the action to the target agent
    handleAnimAction(TargetAgent : agent,ActionType : AnimationTypes, ActionValue : float):void=
        if(TargetFC := TargetAgent.GetFortCharacter[], TargetFC.IsActive[]):
            if(ActionType = AnimationTypes.Combat):
                TargetFC.Damage(ActionValue)
            else if(ActionType = AnimationTypes.Healing):
                TargetFC.Heal(ActionValue)

        


        
