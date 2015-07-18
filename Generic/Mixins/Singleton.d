/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
module Generic.Mixins.Singleton;

/**
 * Mixin or trait that can be used in classes to inject code typical for singleton classes, such as an 'Instance'
 * property that will automatically instantiate the singleton if needed. Making the constructor private is the
 * responsibility of the using class.
 */
mixin template Singleton()
{
    @property
    {
        /**
         * Retrieves the sole instance of this class.
         *
         * @return The sole instance.
         */
        auto public static Instance()
        {
            static typeof(this) instance = null;

            if (!instance)
                instance = new typeof(this)();

            return instance;
        }
    }
}
