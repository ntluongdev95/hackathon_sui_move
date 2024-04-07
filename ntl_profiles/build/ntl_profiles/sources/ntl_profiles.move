
module ntl_profiles::ntl_profiles {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{TxContext,sender};
    use sui::table::{Self, Table};
    use sui::url::{Self,Url};
    use std::string::{Self,utf8, String};
    use sui::display;
    use sui::package::{Self};
    use sui::transfer::{transfer, public_transfer, share_object};
    use sui::dynamic_object_field ;
    use sui::dynamic_field;
    use sui::event::{emit};

    const EEXISTEDPROFILE:u64 =1;

    struct NTL_PROFILES has drop {}
    struct Admin has key {
        id:UID,
    }

     struct ProfilesSystem has key {
        id:UID,
        profiles:Table<address,ID>
    }

    struct Profile has key,store {
        id:UID,
        name:String,
        description:String,
        img_url:Url,
        loyalty_points:u32
    }

    struct EventCreateProfile has copy, drop {
        profile_id:ID,
        creator_id: address,
    }

    fun init (otw:NTL_PROFILES , ctx: &mut TxContext){
        let creator = sender(ctx);
        let adminCap = Admin{ 
            id: object::new(ctx),
         };
        let profilesSystem = ProfilesSystem{
            id: object::new(ctx),
            profiles: table::new(ctx)
        };
        
        let profilesSystem_keys = vector[
          utf8(b"Name"),
          utf8(b"Description"),
          utf8(b"Image Uri"),
          utf8(b"Link"),
        ];
        let profilesSystem_values = vector[
          utf8(b"Profiles Management System"),
          utf8(b"Profiles Management System"),
          utf8(b"https://pbs.twimg.com/card_img/1766108386188464128/1lRmJNor?format=jpg&name=medium"),
          utf8(b"https://sui.io/"),
        ];
        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<ProfilesSystem>(&publisher, profilesSystem_keys, profilesSystem_values, ctx);
   
        display::update_version(&mut display);
        public_transfer(publisher, creator);
        public_transfer(display, creator);
        transfer(adminCap, creator);
        share_object(profilesSystem);
}  
    public entry fun create_profile
        (
         profile_hub:&mut ProfilesSystem,
         name: String, description: String, img_url:String,
         ctx: &mut TxContext) {
        let creator = sender(ctx);
        assert!(!table::contains(&profile_hub.profiles, creator), EEXISTEDPROFILE);
        let profile = Profile{
            id: object::new(ctx),
            name: name,
            description: description,
            img_url: url::new_unsafe(string::to_ascii(img_url)),
            loyalty_points: 0
        };
        let profile_id = object::uid_to_inner(&profile.id);
        emit(EventCreateProfile{
            profile_id:object::uid_to_inner(&profile.id),
            creator_id: creator,
        });
        table::add(&mut profile_hub.profiles, creator, profile_id);
        transfer(profile, creator);
        
    }
    public entry fun edit_profile(
        profile: &mut Profile,
        name: String,
        image_url: String,
        description: String,
        _ctx: &mut TxContext,
    ) {
        profile.name = name;
        profile.img_url = url::new_unsafe(string::to_ascii(image_url));
        profile.description = description;
    }

    public fun add_dynamic_field<Name: copy + drop + store, Value: store>(
         _:&Admin,
        profile: &mut Profile,
        name: Name,
        value: Value,
    ) {
        dynamic_field::add(&mut profile.id, name, value);
    }

    public fun remove_dynamic_field<Name: copy + drop + store, Value: store>(
        _: &Admin,
        profile: &mut Profile,
        name: Name,
    ): Value {
        return dynamic_field::remove(&mut profile.id, name)
    }

    public fun add_dynamic_object_field<Name: copy + drop + store, Value: key + store>(
        _: &Admin,
        profile: &mut Profile,
        name: Name,
        value: Value,
    ) {
        dynamic_object_field::add(&mut profile.id, name, value);
    }
    public fun remove_dynamic_object_field<Name: copy + drop + store, Value: key + store>(
        _: &Admin,
        profile: &mut Profile,
        name: Name,
    ): Value {
        return dynamic_object_field::remove(&mut profile.id, name)
    }



}