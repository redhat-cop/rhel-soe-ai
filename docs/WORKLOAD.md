# Workload
This document describes common workloads hosted on top of the SOE. When new workload items are added all agents needs to re-assess if their technical subsystem requires and changes.

## Workload architecture
When new workload is added it is important to be conservative and allow the current baseline configuration state to be preserved. Workloads should be opt-in add-ons on the current baseline configuration. Do so by adding a common global trigger which activates a specific workload using a variable, following the naming standard of ```workloadname_enable```. If this variable is not set the baseline configuration should be unchanged.

As such, to apply a specific workload for a system, you enable the boolean ```workloadname_enable``` Ansible variable on the group or host level to deploy a specific workload for a system.

# Workload items
If any items are added in this section, that is a trigger to assess the impact on the technical subsystems you are responsible for. Linked files below should be fully digested.

## Example item
This is a example workload item which can be ignored.
