/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module Application.MainWindow.RequestsTree;

import gtk.TreeIter;
import gtk.TreePath;
import gtk.TreeView;
import gtk.TreeStore;
import gtk.TreeViewColumn;
import gtk.CellRendererText;

import gdk.Event;

static import gtk.Builder;

import Generic.Utility;
import Generic.Signal : Signal;
import Generic.Buildable : Buildable;
import Generic.Mixins.ShortcutKeyProvider;

/**
 * Very thin wrapper around the tree view containing the saved requests.
 */
class RequestsTree : Buildable!TreeView
{
    mixin ShortcutKeyProvider;

public:
    static Signal!("deleteRequested", typeof(this), TreeIter)   deleteRequestedSignal;
    static Signal!("activateRequested", typeof(this), TreeIter) activateRequestedSignal;

public:
    /**
     * Constructor.
     *
     * @param builder The builder to use that has the definition file containing the tree loaded.
     * @param id      The ID of the widget in the builder definition file.
     */
    this(gtk.Builder.Builder builder, string id)
    {
        super(builder, id);

        this.connectHandlers();
    }

public:
    @property
    {
        /**
         * Retrieves the store.
         *
         * @return The store.
         */
        TreeStore Store()
        {
            return cast(TreeStore) this.Widget.getModel();
        }

        /**
         * @copydoc Buildable::Widget
         */
        override TreeView Widget()
        {
            // FIXME: Bug in the DMD compiler? Parent uses template parameter as return type but 'gtk.Widget.Widget' is
            // still selected instead when using the class.
            return cast(TreeView) super.Widget;
        }
    }

public:
    /**
     * Starts editing the specified node.
     *
     * @param node The node to start editing.
     */
    void startNameEditor(TreeIter node)
    {
        auto column = this.getWidget!TreeViewColumn("requestsNameColumn");
        auto renderer = this.getWidget!CellRendererText("requestsNameRendererText");

        // NOTE: We do not always enable editing, as otherwise it will also trigger on double click and we will lose
        // the ability to use it to open the file.
        renderer.setProperty("editable", true);
        this.Widget.setCursor(node.getTreePath(), column, true);
        renderer.setProperty("editable", false);
    }

    /**
     * Adds a new request to the tree with the specified name and value for the index column and returns an iterator to
     * it.
     *
     * @param name   The name (display text) of the node to add.
     * @param method The HTTP method to display.
     * @param index  The value to set for the index column.
     * @param parent The parent node to attach the newly created node to, if any.
     *
     * @return An iterator to the newly created node.
     */
    TreeIter addNode(string name, string method, int index, TreeIter parent = null)
    {
        auto iter = new TreeIter();

        auto requestsTreeStore = this.getObject!TreeStore("requestsTreeStore");

        requestsTreeStore.insert(iter, parent, -1);
        requestsTreeStore.setValue(iter, 0, name);
        requestsTreeStore.setValue(iter, 1, index);
        requestsTreeStore.setValue(iter, 2, method);

        return iter;
    }

    /**
     * Updates a node's name and/or method. The parameters can be nulled to ignore them.
     *
     * @param iter   The node to update.
     * @param name   The new name to give to the node.
     * @param method The new method to give to the node.
     */
    void updateNode(TreeIter iter, string name, string method)
    {
        auto requestsTreeStore = this.getObject!TreeStore("requestsTreeStore");

        if (name)
            requestsTreeStore.setValue(iter, 0, name);

        if (method)
            requestsTreeStore.setValue(iter, 2, method);
    }

public:
    /**
     * Emits a signal to delete an item from the tree.
     *
     * @param e The raw event that was sent.
     *
     * @return Whether or not the event should propagate.
     */
    @Shortcut("Delete") bool requestDelete(Event e)
    {
        if (auto iter = this.Widget.getSelectedIter())
            this.deleteRequestedSignal.send(this, iter);

        return EventPropagation.STOP;
    }

    /**
     * Renames the currently selected row.
     *
     * @param e The raw event that was sent.
     *
     * @return Whether or not the event should propagate.
     */
    @Shortcut("F2") @Shortcut("<Control>R") bool renameSelectedRow(Event e)
    {
        if (auto iter = this.Widget.getSelectedIter())
            this.startNameEditor(iter);

        return EventPropagation.STOP;
    }

    /**
     * Collapses the currently selected node.
     *
     * @param e The raw event that was sent.
     *
     * @return Whether or not the event should propagate.
     */
    @Shortcut("Left") bool collapseNode(Event e)
    {
        if (auto iter = this.Widget.getSelectedIter())
            this.Widget.collapseRow(iter.getTreePath());

        return EventPropagation.STOP;
    }

    /**
     * Expands the currently selected node.
     *
     * @param e The raw event that was sent.
     *
     * @return Whether or not the event should propagate.
     */
    @Shortcut("Right") bool expandNode(Event e)
    {
        if (auto iter = this.Widget.getSelectedIter())
            this.Widget.expandRow(iter.getTreePath(), false);

        return EventPropagation.STOP;
    }

protected:
    /**
     * Connects signal/event handlers for widgets.
     */
    void connectHandlers()
    {
        // Connect editing handlers that just confirm the new text the user tried to enter.
        auto requestsTreeStore = this.getObject!TreeStore("requestsTreeStore");
        auto requestsNameRendererText = this.getObject!CellRendererText("requestsNameRendererText");

        void applyUserEnteredText(string storeName, int column)(string pathString, string newText, CellRendererText renderer)
        {
            auto store = mixin(storeName);

            TreePath iterPath = new TreePath(pathString);
            TreeIter iter = new TreeIter(store, iterPath);

            store.setValue(iter, column, newText);
        }

        requestsNameRendererText.addOnEdited(&applyUserEnteredText!("requestsTreeStore", 0));

        this.Widget.addOnKeyPress(&this.onKeyPress);
        this.Widget.addOnRowActivated(&this.onRowActivated);
    }

    /**
     * Called when a node is activated (i.e. clicked in the context of this tree).
     *
     * @param nodePath The path to the node that was activated.
     * @param column   The column that was activated.
     * @param treeView The tree view containing the node that was activated.
     */
    void onRowActivated(TreePath nodePath, TreeViewColumn column, TreeView treeView)
    {
        if (auto iter = this.Widget.getSelectedIter())
            this.activateRequestedSignal.send(this, iter);

        /*TreeIter node = new TreeIter(treeView.getModel(), nodePath);

        if (isFile(path))
            this.entryDoubleClickedSignal.send(path);

        else if (treeView.rowExpanded(nodePath))
            treeView.collapseRow(nodePath);

        else
            treeView.expandRow(nodePath, false);*/
    }
}
