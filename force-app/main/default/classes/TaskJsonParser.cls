public class TaskJsonParser {
    public class TaskWrapper {
        public Date ActivityDate;
        public String Subject;
        public String Description;
        public String WhatId;
        public String Interaction;
    }

    @InvocableMethod
    public static List<List<Task>> parseTaskJson(List<String> jsonInput) {
        List<Task> tasks = new List<Task>();
        List<List<Task>> tasklist = new List<List<Task>>();
        for (String jsonString : jsonInput) {
            List<TaskWrapper> taskWrappers = (List<TaskWrapper>) JSON.deserialize(jsonString, List<TaskWrapper>.class);
            for (TaskWrapper wrapper : taskWrappers) {
                Task task = new Task();
                task.ActivityDate = wrapper.ActivityDate;
                task.Subject = wrapper.Subject;
                task.Description = wrapper.Description;
                task.WhatId = wrapper.WhatId;
                task.OwnerId = UserInfo.getUserId();
                task.Priority = 'Medium';
                task.Type = 'Meeting';
                task.put('Interaction__c', wrapper.Interaction); // Custom field
                tasks.add(task);
            }
        }
        //if(tasks.size() > 0 ){
           // insert tasks;
        //}
        tasklist.add(tasks);
        return tasklist;
    }
}