/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module Generic.Utility;

import gtk.Widget;

import gdk.Threads;

import std.conv;
import std.array;
import std.string;
import std.typecons;
import std.algorithm;

import core.memory;
import core.stdc.string;

import glib.Variant;
import glib.KeyFile;

public import Generic.Localization.Translator;

/**
 * Some glib.VariantType constants for convenience, as these don't seem to be provided by gtkd yet.
 *
 * @see http://dbus.freedesktop.org/doc/dbus-specification.html
 */
enum VariantTypeID
{
    STRING = "s",
    UINT64 = "t"
}

/**
 * Integer-based mouse button identifiers.
 */
enum MouseButton : uint
{
    LEFT   = 1,
    MIDDLE = 2,
    RIGHT  = 3
}

/**
 * Simply because it seems to be missing from GTKd.
 *
 * @link https://developer.gnome.org/gtk3/stable/GtkStyleProvider.html
 */
enum StyleProviderPriority : uint
{
    FALLBACK    = 1,
    THEME       = 200,
    SETTINGS    = 400,
    APPLICATION = 600,
    USER        = 800
}

/**
 * Not an enum because they don't implicitly convert and require a cast when using them as booleans. GtkD doesn't seem
 * to define these constants from GTK.
 */
struct EventPropagation
{
    immutable static bool PROPAGATE = false;
    immutable static bool STOP = true;
}

/**
 * Replaces the specified character 'searchFor' with 'replaceWith' for each occurrence in 'subject'.
 *
 * @param subject     The string to replace in.
 * @param searchFor   The text to search for.
 * @param replaceWith The replacement string.
 *
 * @return A new string with the replacements applied.
 */
pure string replace(string subject, char searchFor, char replaceWith)
{
    string result;

    foreach (c; subject)
        result ~= (c != searchFor)? c : replaceWith;

    return result;
}

/**
 * Removes the specified element from the array (once).
 *
 * @param array   The array to remove the item from.
 * @param element The item to look for and remove.
 */
void remove(T)(ref T[] array, T element)
{
    array = std.algorithm.remove(array, array.indexOf(element));
}

/**
 * Convenience function that returns, but does not remove, the last element of an array (stack). Returns null if the
 * array is empty.
 *
 * @param array The array to peek in.
 *
 * @return The last element (or null if none).
 */
Nullable!T peek(T)(T[] array)
{
    Nullable!T t;

    if (array.length > 0)
        t = array[$ - 1];

    return t;
}

/**
 * Convenience function that removes and returns the last element of an array (stack).
 *
 * @param array The array to pop.
 *
 * @return The popped element.
 */
T pop(T)(ref T[] array)
{
    T element = array[$ - 1];

    array = array[0 .. $ - 1];

    return element;
}

/**
 * Compatibility function because apparently GDC (5.1) doesn't include std.string.assumeUTF.
 *
 * @param data The raw UTF-8 data that is to be casted to an UTF-8 string.
 *
 * @return A string containing the data.
 */
pure string assumeUTF8Compat(immutable(ubyte[]) data)
{
    auto result = new char[data.length];

    foreach (i, octet; data)
        result[i] = octet;

    return to!string(result);
}

/**
 * GVariant doesn't allow storing pointer types. This works around that limitation by storing the memory address of the
 * object in the GVariant instead. This should only be used internally as this representation can vary per platform.
 *
 * @param o The data to put in a variant.
 *
 * @return The variant containing the specified data.
 */
/*Variant toVariant(T)(ref const T o)
{
    return new Variant(cast(ulong) &o);
}*/

/**
 * Retrieves an object of the specified type from the specified variant. See also {@link toVariant}.
 *
 * @param v The variant to extract data from.
 *
 * @return The data as the requested type.
 */
/*T getObject(T)(Variant v)
{
    return *(cast(T*) (v.getUint64()));
}*/

/**
 * Loops up the widget stack, looking for the instance of this class that is the parent of the specified widget.
 * Returns null if there is none.
 *
 * Usage of this function, especially in delegates, is very important. When cells are merged, tabs are moved from
 * one instance of this class to another, which doesn't update the 'this' instance inside a delegate.
 *
 * @param widget The widget of which to search an ancestor.
 *
 * @return The first ancestor of the requested type or null.
 */
T getAncestorOfType(T)(Widget widget)
{
    while (widget)
    {
        widget = widget.getParent();

        if (auto ancestor = cast(T) widget)
            return ancestor;
    }

    return null;
}

/**
 * Maps a widget to the specified entry, causing its activation (e.g. by pressing the return key in the entry input
 * field) to confirm the current action by 'activating' (i.e. pressing) the specified button. For example, this can be
 * used to map all form fields to a save button, causing a press of the return key in each of the form fields to
 * trigger the save.
 *
 * @param entry
 * @param widgetToActivate
 */
void setConfirmationButton(gtk.Entry.Entry entry, Widget widgetToActivate)
{
    entry.addOnActivate((gtk.Entry.Entry sender) {
        widgetToActivate.activate();
    });
}

/**
 * Some utility functions extending the KeyFile class.
 */
private bool hasGroupAndKey(KeyFile file, string groupName, string key)
{
    return (file.hasGroup(groupName) && file.hasKey(groupName, key));
}

auto getIntegerDefault(KeyFile file, string groupName, string key, int defaultValue)
{
    return file.hasGroupAndKey(groupName, key) ? file.getInteger(groupName, key) : defaultValue;
}

auto getDoubleDefault(KeyFile file, string groupName, string key, double defaultValue)
{
    return file.hasGroupAndKey(groupName, key) ? file.getDouble(groupName, key) : defaultValue;
}

auto getBooleanDefault(KeyFile file, string groupName, string key, bool defaultValue)
{
    return cast(bool) (file.hasGroupAndKey(groupName, key) ? file.getBoolean(groupName, key) : defaultValue);
}

auto getStringDefault(KeyFile file, string groupName, string key, string defaultValue)
{
    return file.hasGroupAndKey(groupName, key) ? file.getString(groupName, key) : defaultValue;
}

auto getIntegerListDefault(KeyFile file, string groupName, string key, int[] defaultValue)
{
    return file.hasGroupAndKey(groupName, key) ? file.getIntegerList(groupName, key) : defaultValue;
}

auto getStringListDefault(KeyFile file, string groupName, string key, string[] defaultValue)
{
    return file.hasGroupAndKey(groupName, key) ? file.getStringList(groupName, key) : defaultValue;
}

/**
 * Simple structure that contains a pointer to a delegate. This is necessary because delegates are not directly
 * convertable to a simple pointer (which is needed to pass as data to a C callback).
 */
struct DelegatePointer(ReturnType, Parameters...)
{
    ReturnType delegate(Parameters) delegateInstance;

    /**
     * Constructor.
     *
     * @param delegateInstance The delegate to invoke.
     */
    public this(ReturnType delegate(Parameters) delegateInstance)
    {
        this.delegateInstance = delegateInstance;
    }
}

/**
 * Callback that will invoke the passed DelegatePointer's delegate when it is called. This very useful method can be
 * used to pass delegates in places where callbacks with C linkage are expected (such as GSourceFunc).
 *
 * The return type is the type that should be returned by this function. The invoked delegate should as a best practice
 * return the same value. If an exception happens and the value from the delegate can't be returned, the '.init' value
 * of the type will be used instead (or nothing in the case of void).
 *
 * @param parameters      Parameters that are passed to the callback function.
 * @param delegatePointer Should contain a pointer to the the DelegatePointer instance.
 *
 * @return Whatever the delegate returns.
 */
extern(C) nothrow static ReturnType invokeDelegatePointerFunc(DataType, ReturnType, Parameters...)(
    Parameters parameters,
    void* delegatePointer
) {
    try
    {
        // Explicit cast needed for void return types.
        return cast(ReturnType) (cast(DataType) delegatePointer).delegateInstance(parameters);
    }

    catch (Exception e)
    {
        // Just catch it, can't throw D exceptions accross C boundaries.
        static if (__traits(compiles, ReturnType.init))
            return ReturnType.init;
    }

    // Should only end up here for types that don't have an initial value (such as void).
}

/**
 * Takes a delegate and returns a tuple containing a reference to a function with C linkage that can be
 * passed as callback to various methods that require one from GTK. The second element of the tuple is
 * a void pointer that must be passed as the 'user data' along with the callback with C linkage.
 */
auto delegateToCallbackTuple(ReturnType, Parameters...)(ReturnType delegate(Parameters) theDelegate)
{
    import std.typecons : Tuple;

    auto delegatePointer = new DelegatePointer!(ReturnType, Parameters)(theDelegate);

    auto callback = &invokeDelegatePointerFunc!(typeof(delegatePointer), ReturnType, Parameters);
    auto dataForCallback = cast(void*) delegatePointer;

    return Tuple!(typeof(callback), "callback", typeof(dataForCallback), "data")(
        callback,
        dataForCallback
    );
}

/**
 * Convenience method that allows scheduling a delegate to be executed with gdk.Threads.threadsAddIdle instead of a
 * traditional callback with C linkage.
 *
 * @param theDelegate The delegate to schedule.
 *
 * @example threadsAddIdleDelegate(delegate() { do_something(); return false; });
 */
void threadsAddIdleDelegate(int delegate() theDelegate)
{
    void* delegatePointerToFree = null;

    auto wrapperDelegate = delegate() {
        int callAgainNextIdleCycle = false;

        try
        {
            callAgainNextIdleCycle = theDelegate();
        }

        catch (Exception e)
        {
            // Catch exceptions here as otherwise, memory may never be freed below.
        }

        if (!callAgainNextIdleCycle)
            core.memory.GC.removeRoot(delegatePointerToFree);

        return cast(int) callAgainNextIdleCycle;
    };

    auto callbackTuple = delegateToCallbackTuple(wrapperDelegate);

    delegatePointerToFree = callbackTuple.data;

    // We're going into a separate thread and exiting here, make sure the garbage collector doesn't think the memory
    // isn't used anymore and collects it.
    core.memory.GC.addRoot(delegatePointerToFree);

    gdk.Threads.threadsAddIdle(callbackTuple.callback, callbackTuple.data);
}
