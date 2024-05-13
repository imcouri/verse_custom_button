

<#

    CREATED BY: FN_COURI
    DATE: 13/05/2024

    DESCRIPTION:
    This script is a custom button device that aims to improve the default UEFN button_device and can be used to create buttons that can perform a variety of actions when pressed.


    HOW TO USE:
        1. Place a normal UEFN button device in the level
        2. Place the custom button manager device in your level
        3. Click on the custom button manager device, and in the custom button list, add a new custom button
        4. Assign the normal button device and any other device(cinematic, tracker, camera etc) to their respective fields in the custom button

    ENJOY!


    IMPORTANT:
    The following script is provided under the MIT License (https://opensource.org/license/mit)
        You can:
            - Use the script for commercial purposes
            - Modify the script
            - Distribute the script
            - Sublicense the script
            - Use the script privately

        You cannot:
            - Hold the author liable 
            - Use the script for trademark use
            - Use the script for patent use

    NOTE : This script is a work in progress and may contain bugs, please report any bugs you find to me on Twitter/X @FnCouri
    I will be updating this script with more features and improvements in the future, so stay tuned!
#>



using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }




custom_button := class<concrete>():

    #the UI shown when the player is viewing the button 
    var RotationUI : canvas = canvas{}
    
    #the button devcie itself
    @editable
    Button : button_device = button_device{}

    #a cinematic that you cant to play when the button is pressed
    @editable
    Cinematic : ?cinematic_sequence_device = false

    #determines if the button should be disabled after it is pressed
    @editable
    DisableOnEnd : logic = false

    #an audio player device that you want to play when the button is pressed
    @editable
    AudioPlayer : ?audio_player_device = false

    

    #custom hud message to show errors/messages
    @editable
    HudMessage : ?hud_message_device = false

    #automatically increments the progress on this tracker when the button is pressed
    @editable
    ProgressTracker : ?tracker_device = false

    #the item id that you want to grant to the player when the button is pressed (this is for a custom inventory system that i will upload soon, ignore this for now)
    @editable
    GrantCustomItemID : ?int = false


    #a list of buttons that will be enabled when the button is pressed
    @editable
    EnableButtonsOnEnd : ?[]button_device = false

    #a list of switches that must be true(on) in order for the button to work
    @editable
    PreRequisiteSwitches : ?[]switch_device = false

    #a message that will be shown if the pre-requisites are not met
    @editable
    PreReqNotMetMessage : ?string = false

    #allows the player to view/interact with the mesh assigned to the button
    @editable
    ViewOnInteract : logic = false
    
    #the axis that the player will be able to rotate the mesh around/inspect the mesh
    @editable
    InteractRotationAxis : ?string = false

    #a custom camera that will be used when the player is viewing the mesh
    @editable
    InteractionCustomCamera : ?gameplay_camera_fixed_point_device = false

    #how the button should move when the button is viewed
    @editable
    InteractionMovementOffset : ?vector3 = false

    #checks if an item is in the players inventory (this is for a custom inventory system that i will upload soon, ignore this for now)
    @editable
    CheckForItemInInventory : ?int = false

    #if the item defined in CheckForItemInInventory should be consumed when the button is pressed (again, this is for the custom inventory system, ignore for now)
    @editable
    ConsumeOnItemCheck : logic = false

    #signaled when the player is done viewing the mesh
    InteractionUIClosedEvent : event() = event(){}


    #this function is the main function that is called when the button is pressed
    ButtonPressedEvent(Agent : agent):void=
        PreReqCheck :logic = CheckPreRequisites(Agent)
        if(PreReqCheck = true):
            if(IsPlacerButton := CheckForItemInInventory?):
                spawn:
                    OnPlacerButtonPressed(Agent)
            else:
                spawn:
                    OnRegularButtonPressed(Agent)

        else:
            Print("PreRequisites not met")
            if(HasNotMetMsg := PreReqNotMetMessage?):
                Print("Has Not Met Message")
                if(HasHudeMessage := HudMessage?):
                    Print("Has Hud Message")
                    HasHudeMessage.SetText(DynamicText(HasNotMetMsg))
                    HasHudeMessage.Show(Agent)


    #checks if the pre-requisites are met
    CheckPreRequisites(Agent : agent):logic=
        if(HasPreReqSwitches := PreRequisiteSwitches?):
            for(Switch : HasPreReqSwitches):
                Print("Checking Switch")
                if(SwitchState := Switch.GetCurrentState[]):
                else:
                    return false
            return true
        else:
            return true

    #Called when a 'Regular' button is pressed
    <#
        #Regular buttons are buttons are buttons that don't open the inventory UI (the custom inventory system in this case)
    #>
    OnRegularButtonPressed(Agent : agent)<suspends>:void=
        Print("Regular button pressed")
        if(ViewOnInteract = true):
            ViewItem(Agent)

        if(DisableOnEnd = true):
            Button.Disable()

        GeneralButtonActions(Agent)


    #Called when a 'Placer' button is pressed
    <#
        #Placer buttons are buttons that are used to place items in the world, they have a different set of actions that are performed when they are pressed
        #IMPORTANT : Buttons are NOT actually placed in the world using this function, you need to still use a cinematic sequence to place the item in the world, this function just takes care of inventory management and some other minor things.
    #>
    OnPlacerButtonPressed(Agent : agent)<suspends>:void=
        Print("Placer button pressed")
        HasItem : tuple(logic,logic)= CheckPlayerInventory(Agent) #returns logic(result),logic(wether it was cancelled or not)

        if(HasItem(1) = false):
            if(HasItem(0) = true):
                if(DisableOnEnd = true):
                    Button.Disable()
    
                GeneralButtonActions(Agent)
    
            else:
                if(HasHudeMessage := HudMessage?):
                    Print("Has Hud Message")
                    HasHudeMessage.SetText(DynamicText("This item cannot be used here"))
                    HasHudeMessage.Show(Agent)


                    


    #general actions that are performed when either type of button is pressed
    <#
         #This function performs actions in an asynchronous manner, therefore each action is performed only AFTER the previous action has completed
         #If you want to perform actions simultaneously, you can remove the <suspends> keyword from the function definition, but any async functions should be put inside a spawn block           
    #>
    GeneralButtonActions(Agent : agent)<suspends>:void=

        #plays the cinematic if defined
        if (HasCinematic := Cinematic?):
            HasCinematic.Play()
            HasCinematic.StoppedEvent.Await()

        #increments the progress on the tracker if defined
        if(HasProgress := ProgressTracker?):
            HasProgress.Increment(Agent)

        #grants the player the item if defined (IGNORE FOR NOW)
        if(HasCustomItemID := GrantCustomItemID?):
            if(ViewOnInteract = false):
                Print("Button Grants Item")
                GrantCustomItem(Agent,HasCustomItemID)

        #buttons that are enabled when the button is pressed
        if(HasEnableButtons := EnableButtonsOnEnd?):
            for(ShouldEnableButton : HasEnableButtons):
                ShouldEnableButton.Enable()

        #plays the audio if defined
        if(HasAudio := AudioPlayer?):
            HasAudio.Play()
                

        
        
    # !- CUSTOM INVENTORY SYSTEM FUNCTIONS - IGNORE FOR NOW -!     
    GrantCustomItem(Agent : agent, ItemID : int):void=
        if(Player := player[Agent]):
            if(CustomPlayer := CustomPlayerList[GetSession()][Player]):
                MaybeCustomItemObj := CustomPlayer.InventoryManager.GetItem(ItemID)
                if(CustomItemObj := MaybeCustomItemObj?):
                    HasSpace := CustomPlayer.InventoryManager.HasSpace()
                    if(HasSpace = true):
                        CustomPlayer.InventoryManager.AddToInventory(CustomItemObj)
                        CustomPlayer.InventoryManager.RemoveFromGlobalInventory(ItemID)

    # !- CUSTOM INVENTORY SYSTEM FUNCTIONS - IGNORE FOR NOW -!                    
    CheckPlayerInventory(Agent : agent)<suspends>:tuple(logic,logic)=
        if(HasInventoryCheck := CheckForItemInInventory?):
            if(Player := player[Agent]):
                if(CustomPlayer := CustomPlayerList[GetSession()][Player]):
                    SelectedItem : ?int = CustomPlayer.SelectItemFromInventory()
                    if(HasSelectedItem := SelectedItem?):
                        if(HasSelectedItem <> -1):
                            if(HasSelectedItem = HasInventoryCheck):
                                InventoryCheck := CustomPlayer.InventoryManager.CheckIfItemInInventory(HasSelectedItem,ConsumeOnItemCheck)
                                if(InventoryCheck = true):
                                    Print("Checked and consumed item")
                                    return (true,false)
                                else:
                                    Print("Failed to check and consume item")
                                    return (false,false)
                            else:
                                Print("Selected Item does not match the required item ID")
                        else:
                            return (false,true)
                    else:
                        Print("No Selected Item")
                else:
                    Print("No Custom Player Found")
            
            else:
                Print("No Player Found")
          

        else:
            Print("No Inventory Check")
                    
        return (false,false)



    DynamicText<localizes>(msg : string) : message = "{msg}"



    #called when a buttton that can be viewed is pressed
    ViewItem(Agent : agent)<suspends>:void=

        #stores the original transform of the button so that it can be reset after the player is done viewing the button
        ButtonOriginalTransform := Button.GetTransform()
        ButtonRotation := ButtonOriginalTransform.Rotation

        if(Player := player[Agent]):
            ShowRotationUI(Player)
            
            #moves the button to a new location when the player is viewing the button
            if(HasOffset :=InteractionMovementOffset?):
                if:
                    Button.TeleportTo[ButtonOriginalTransform.Translation + HasOffset,ButtonRotation]
            
            #adds a custom camera to the player if defined
            if(HasCustomCamera := InteractionCustomCamera?):
                HasCustomCamera.AddTo(Agent)


            #waits for the player to be done viewing the button
            InteractionUIClosedEvent.Await()
            
            #removes the custom camera from the player
            if(HasCustomCamera := InteractionCustomCamera?):
                HasCustomCamera.RemoveFrom(Agent)

            if:
                #resets the button to its original transform
                Button.TeleportTo[ButtonOriginalTransform.Translation,ButtonRotation]

        
                


    #shows the button viewing UI
    ShowRotationUI(Player : player):void=
        if(PlayerUI := GetPlayerUI[Player]):
            Button.Disable()
            RotationCanvas := CreateRotationUI()
            PlayerUI.AddWidget(RotationCanvas,player_ui_slot{InputMode:=ui_input_mode.All})
            set RotationUI = RotationCanvas

    #closes the button viewing UI
    CloseRotationUI(Player : player):void=
        if(PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(RotationUI)
            set RotationUI = canvas{}
            Button.Enable()
            InteractionUIClosedEvent.Signal()

    #creates the UI for the player to view the button
    CreateRotationUI():canvas=
        RotationCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.8}, Maximum := vector2{X := 0.5, Y := 0.8}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    Widget:= GetStackBox()

        return RotationCanvas

    #creates the buttons for the rotation UI
    GetStackBox():stack_box=

        RotateLeftButton := button_quiet{DefaultText := DynamicText("← Left")}
        RotateRightButton := button_quiet{DefaultText := DynamicText("Right →")}

        RotateLeftButton.OnClick().Subscribe(RotateLeftButtonClicked)
        RotateRightButton.OnClick().Subscribe(RotateRightButtonClicked)

        TakeButton := button_loud{DefaultText := DynamicText("Take")}
        ExitButton := button_loud{DefaultText := DynamicText("Exit")}

        TakeButton.OnClick().Subscribe(AddToInventoryButton)
        ExitButton.OnClick().Subscribe(CloseButtonClicked)


        StackBox : stack_box =stack_box:
            Orientation := orientation.Horizontal


        StackBox.AddWidget(stack_box_slot{Widget := RotateLeftButton})

        StackBox.AddWidget(stack_box_slot{Widget := ExitButton})
        

        if(HasInventoryId := GrantCustomItemID?):
            StackBox.AddWidget(stack_box_slot{Widget := TakeButton})

        StackBox.AddWidget(stack_box_slot{Widget := RotateRightButton})

        return StackBox
            

    CloseButtonClicked(wParam : widget_message):void=
        CloseRotationUI(wParam.Player)

    #adds the viewing item to the player's inventory
    AddToInventoryButton(wParam : widget_message):void=
        if(HasItemID := GrantCustomItemID?):
            GrantCustomItem(wParam.Player,HasItemID)
            CloseRotationUI(wParam.Player)

    #rotates the mesh to the left
    RotateLeftButtonClicked(wParam : widget_message):void=
        RotateViewingItem(false)

    #rotates the mesh to the right
    RotateRightButtonClicked(wParam : widget_message):void=
        RotateViewingItem(true)


            

    #rotates the mesh around the axis defined in InteractRotationAxis
    RotateViewingItem(TurnRight : logic):void=
        var RotateMeshBy :float = 0.0
        if(TurnRight = true):
            set RotateMeshBy = 20.0
        else:
            set RotateMeshBy = -20.0

        set RotateMeshBy = DegreesToRadians(RotateMeshBy)

        var ButtonRotation : rotation = Button.GetTransform().Rotation

        if(RotateAround := InteractRotationAxis?):
            case(RotateAround):
                "x" => set ButtonRotation = ButtonRotation.ApplyRoll(RotateMeshBy)
                "y" => set ButtonRotation = ButtonRotation.ApplyPitch(RotateMeshBy)
                "z" => set ButtonRotation = ButtonRotation.ApplyYaw(RotateMeshBy)
                _ => set ButtonRotation = ButtonRotation.ApplyYaw(RotateMeshBy)

            if(Rotate := Button.TeleportTo[Button.GetTransform().Translation,ButtonRotation]):
                Print("Rotated")
            else:
                Print("Failed to rotate")



        
# A Verse-authored creative device that can be placed in a level
custom_button_manager := class(creative_device):

    @editable
    CustomButtonList : []custom_button = array{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        #Subscribes to every custom button's click event
        for(CustomButton : CustomButtonList):
            CustomButton.Button.InteractedWithEvent.Subscribe(CustomButton.ButtonPressedEvent)




    

    

        
