# Vertical policy
This document describes overall vertical policies. Policies which works like opt-in add-ons to the baseline Standard Operating Environment. When new policy items are added all agents needs to re-assess if their technical subsystem requires and changes.

## Policy architecture
When new policy is added it is important to be conservative and allow the current baseline configuration state to be preserved. Do so by adding a common global trigger which activates policy compliance using a variable, following the naming standard of ```policyname_enable```. If this variable is not set or set to false, the baseline configuration should be unchanged.

As such, to apply policy compliance for a system, you enable the boolean ```policyname_enable``` Ansible variable on the group or host level to enforce specific compliance for a system.

# Policy items
If any items or changes are added in this section, that is a trigger to assess the impact on the technical subsystems you are responsible for. Linked files below should be fully digested.

## Example item
This is a example policy item which can be ignored.

